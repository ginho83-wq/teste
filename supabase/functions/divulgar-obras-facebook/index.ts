import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get(
  "SUPABASE_SERVICE_ROLE_KEY",
);
const FACEBOOK_PAGE_ID = Deno.env.get("FACEBOOK_PAGE_ID");
const FACEBOOK_PAGE_ACCESS_TOKEN = Deno.env.get(
  "FACEBOOK_PAGE_ACCESS_TOKEN",
);

const URL_BASE_OBRA =
  "https://ginho83-wq.github.io/teste/obra/";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return Response.json(
      { sucesso: false, erro: "Utilize o método POST." },
      { status: 405 },
    );
  }

  const authorization = req.headers.get("Authorization");

  if (!authorization?.startsWith("Bearer ")) {
    return Response.json(
      { sucesso: false, erro: "Sessão não fornecida." },
      { status: 401 },
    );
  }

  const token = authorization.substring("Bearer ".length).trim();

  if (
    !SUPABASE_URL ||
    !SUPABASE_SERVICE_ROLE_KEY ||
    !FACEBOOK_PAGE_ID ||
    !FACEBOOK_PAGE_ACCESS_TOKEN
  ) {
    console.error("Faltam variáveis de ambiente obrigatórias.");

    return Response.json(
      {
        sucesso: false,
        erro: "A configuração da função está incompleta.",
      },
      { status: 500 },
    );
  }

  // Cliente com a sessão recebida do Flutter.
  // A autorização é verificada com o utilizador autenticado.
  const supabaseUtilizador = createClient(
    SUPABASE_URL,
    Deno.env.get("SUPABASE_ANON_KEY") ??
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
      "",
    {
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    },
  );

  try {
    const { data: utilizadorData, error: utilizadorErro } =
      await supabaseUtilizador.auth.getUser(token);

    if (utilizadorErro || !utilizadorData.user) {
      return Response.json(
        { sucesso: false, erro: "Sessão inválida ou expirada." },
        { status: 401 },
      );
    }

    const { data: ehAdmin, error: adminErro } =
      await supabaseUtilizador.rpc("eh_admin");

    if (adminErro) {
      console.error("Erro ao verificar administrador:", adminErro);

      return Response.json(
        {
          sucesso: false,
          erro: "Não foi possível verificar as permissões.",
        },
        { status: 500 },
      );
    }

    if (ehAdmin !== true) {
      return Response.json(
        {
          sucesso: false,
          erro: "Acesso permitido apenas a administradores.",
        },
        { status: 403 },
      );
    }

    // Cliente privilegiado: utilizado exclusivamente no servidor.
    const supabaseAdmin = createClient(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    const { data: divulgacoes, error: filaErro } =
      await supabaseAdmin
        .from("divulgacoes_redes_sociais")
        .select("*")
        .eq("plataforma", "facebook")
        .eq("estado", "pendente")
        .order("created_at", { ascending: true })
        .limit(10);

    if (filaErro) {
      throw new Error(`Erro ao consultar a fila: ${filaErro.message}`);
    }

    if (!divulgacoes || divulgacoes.length === 0) {
      return Response.json({
        sucesso: true,
        mensagem: "Não existem divulgações pendentes.",
        processadas: 0,
        resultados: [],
      });
    }

    const resultados: Array<Record<string, unknown>> = [];

    for (const divulgacao of divulgacoes) {
      try {
        if (!divulgacao.obra_id) {
          throw new Error("A divulgação não possui obra_id.");
        }

        const { data: obra, error: obraErro } =
          await supabaseAdmin
            .from("obras")
            .select(
              "id,titulo,descricao_editorial,conteudo_editorial",
            )
            .eq("id", divulgacao.obra_id)
            .maybeSingle();

        if (obraErro) {
          throw new Error(
            `Erro ao consultar a obra: ${obraErro.message}`,
          );
        }

        if (!obra) {
          throw new Error("Obra não encontrada.");
        }

        const titulo = String(
          obra.titulo ?? "Obra académica",
        );

        const descricao = String(
          obra.descricao_editorial ??
            obra.conteudo_editorial ??
            "",
        );

        const urlObra = `${URL_BASE_OBRA}${obra.id}`;

        const mensagem = [
          titulo,
          "",
          descricao.slice(0, 700),
          "",
          "Consulte esta obra na plataforma Obra Livre:",
          urlObra,
          "",
          "#ObraLivre #InvestigacaoCientifica #Conhecimento",
        ].join("\n");

        // Publicar na página do Facebook.
        const facebookResponse = await fetch(
          `https://graph.facebook.com/v23.0/${FACEBOOK_PAGE_ID}/feed`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: mensagem,
              access_token: FACEBOOK_PAGE_ACCESS_TOKEN,
            }),
          },
        );

        const facebookResult = await facebookResponse.json();

        if (!facebookResponse.ok || !facebookResult.id) {
          throw new Error(
            `Facebook: ${JSON.stringify(facebookResult)}`,
          );
        }

        const { error: atualizarErro } = await supabaseAdmin
          .from("divulgacoes_redes_sociais")
          .update({
            estado: "publicado",
            mensagem,
          })
          .eq("id", divulgacao.id);

        if (atualizarErro) {
          throw new Error(
            "A publicação foi enviada, mas não foi possível " +
              `actualizar a fila: ${atualizarErro.message}`,
          );
        }

        resultados.push({
          id: divulgacao.id,
          obra_id: obra.id,
          estado: "publicado",
          facebook_post_id: facebookResult.id,
        });
      } catch (error) {
        const erro = error instanceof Error
          ? error.message
          : String(error);

        console.error(
          `Erro na divulgação ${divulgacao.id}:`,
          erro,
        );

        // Registar o erro para diagnóstico.
        const { error: atualizarErro } = await supabaseAdmin
          .from("divulgacoes_redes_sociais")
          .update({
            estado: "erro",
            erro: erro.slice(0, 2000),
          })
          .eq("id", divulgacao.id);

        resultados.push({
          id: divulgacao.id,
          estado: "erro",
          erro,
          atualizacao_registada: !atualizarErro,
        });
      }
    }

    return Response.json({
      sucesso: true,
      processadas: resultados.length,
      resultados,
    });
  } catch (error) {
    const mensagem = error instanceof Error
      ? error.message
      : String(error);

    console.error("Erro na divulgação Facebook:", mensagem);

    return Response.json(
      {
        sucesso: false,
        erro: mensagem,
      },
      { status: 500 },
    );
  }
});

