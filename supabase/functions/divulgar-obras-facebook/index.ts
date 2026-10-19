import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// ============================================================
// CONFIGURAÇÃO
// ============================================================

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");

const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get(
  "SUPABASE_SERVICE_ROLE_KEY",
);

const SUPABASE_ANON_KEY =
  Deno.env.get("SUPABASE_ANON_KEY") ??
  Deno.env.get("SUPABASE_PUBLISHABLE_KEY");

const FACEBOOK_PAGE_ID = Deno.env.get("FACEBOOK_PAGE_ID");

const FACEBOOK_PAGE_ACCESS_TOKEN = Deno.env.get(
  "FACEBOOK_PAGE_ACCESS_TOKEN",
);

const URL_BASE_OBRA =
  "https://ginho83-wq.github.io/teste/obra/";

const FACEBOOK_GRAPH_VERSION = "v23.0";

// ============================================================
// CORS
// ============================================================

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ============================================================
// RESPOSTAS JSON
// ============================================================

function respostaJSON(
  dados: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(dados), {
    status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

// ============================================================
// FUNÇÃO PRINCIPAL
// ============================================================

Deno.serve(async (req: Request) => {
  // ----------------------------------------------------------
  // 1. TRATAR CORS
  // ----------------------------------------------------------

  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: CORS_HEADERS,
    });
  }

  // ----------------------------------------------------------
  // 2. VALIDAR MÉTODO HTTP
  // ----------------------------------------------------------

  if (req.method !== "POST") {
    return respostaJSON(
      {
        sucesso: false,
        erro: "Utilize o método POST.",
      },
      405,
    );
  }

  // ----------------------------------------------------------
  // 3. VALIDAR SESSÃO
  // ----------------------------------------------------------

  const authorization = req.headers.get("Authorization");

  if (!authorization?.startsWith("Bearer ")) {
    return respostaJSON(
      {
        sucesso: false,
        erro: "Sessão não fornecida.",
      },
      401,
    );
  }

  const token = authorization
    .substring("Bearer ".length)
    .trim();

  // ----------------------------------------------------------
  // 4. VALIDAR CONFIGURAÇÃO
  // ----------------------------------------------------------

  if (
    !SUPABASE_URL ||
    !SUPABASE_SERVICE_ROLE_KEY ||
    !SUPABASE_ANON_KEY ||
    !FACEBOOK_PAGE_ID ||
    !FACEBOOK_PAGE_ACCESS_TOKEN
  ) {
    console.error(
      "Faltam variáveis de ambiente obrigatórias.",
    );

    return respostaJSON(
      {
        sucesso: false,
        erro:
          "A configuração da função está incompleta. " +
          "Verifique os segredos do Supabase.",
      },
      500,
    );
  }

  // ----------------------------------------------------------
  // 5. CLIENTE DO UTILIZADOR
  // ----------------------------------------------------------

  const supabaseUtilizador = createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY,
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
    // --------------------------------------------------------
    // 6. VALIDAR TOKEN DO UTILIZADOR
    // --------------------------------------------------------

    const {
      data: utilizadorData,
      error: utilizadorErro,
    } = await supabaseUtilizador.auth.getUser(token);

    if (utilizadorErro || !utilizadorData.user) {
      return respostaJSON(
        {
          sucesso: false,
          erro: "Sessão inválida ou expirada.",
        },
        401,
      );
    }

    // --------------------------------------------------------
    // 7. VERIFICAR ADMINISTRADOR
    // --------------------------------------------------------

    const {
      data: ehAdmin,
      error: adminErro,
    } = await supabaseUtilizador.rpc("eh_admin");

    if (adminErro) {
      console.error(
        "Erro ao verificar administrador:",
        adminErro,
      );

      return respostaJSON(
        {
          sucesso: false,
          erro:
            "Não foi possível verificar as permissões " +
            "do administrador.",
        },
        500,
      );
    }

    if (ehAdmin !== true) {
      return respostaJSON(
        {
          sucesso: false,
          erro:
            "Acesso permitido apenas a administradores.",
        },
        403,
      );
    }

    // --------------------------------------------------------
    // 8. CLIENTE ADMINISTRATIVO DO SUPABASE
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // 9. CONSULTAR FILA DE DIVULGAÇÕES
    // --------------------------------------------------------

    const {
      data: divulgacoes,
      error: filaErro,
    } = await supabaseAdmin
      .from("divulgacoes_redes_sociais")
      .select("*")
      .eq("plataforma", "facebook")
      .eq("estado", "pendente")
      .order("created_at", { ascending: true })
      .limit(10);

    if (filaErro) {
      console.error(
        "Erro ao consultar a fila:",
        filaErro,
      );

      return respostaJSON(
        {
          sucesso: false,
          erro:
            "Não foi possível consultar a fila de divulgação.",
        },
        500,
      );
    }

    // --------------------------------------------------------
    // 10. VERIFICAR SE EXISTEM DIVULGAÇÕES
    // --------------------------------------------------------

    if (!divulgacoes || divulgacoes.length === 0) {
      return respostaJSON({
        sucesso: true,
        mensagem: "Não existem divulgações pendentes.",
        processadas: 0,
        resultados: [],
      });
    }

    // --------------------------------------------------------
    // 11. PROCESSAR DIVULGAÇÕES
    // --------------------------------------------------------

    const resultados: Array<Record<string, unknown>> = [];

    for (const divulgacao of divulgacoes) {
      try {
        // ----------------------------------------------------
        // 11.1. VALIDAR ID DA OBRA
        // ----------------------------------------------------

        if (!divulgacao.obra_id) {
          throw new Error(
            "A divulgação não possui obra_id.",
          );
        }

        // ----------------------------------------------------
        // 11.2. CARREGAR OBRA
        // ----------------------------------------------------

        const {
          data: obra,
          error: obraErro,
        } = await supabaseAdmin
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

        // ----------------------------------------------------
        // 11.3. PREPARAR PUBLICAÇÃO
        // ----------------------------------------------------

        const titulo = String(
          obra.titulo ?? "Obra académica",
        ).trim();

        const descricao = String(
          obra.descricao_editorial ??
            obra.conteudo_editorial ??
            "",
        )
          .replace(/\s+/g, " ")
          .trim();

        const urlObra =
          `${URL_BASE_OBRA}${obra.id}`;

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

        // ----------------------------------------------------
        // 11.4. PUBLICAR NO FACEBOOK
        // ----------------------------------------------------

        const facebookResponse = await fetch(
          `https://graph.facebook.com/` +
            `${FACEBOOK_GRAPH_VERSION}/` +
            `${FACEBOOK_PAGE_ID}/feed`,
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

        if (
          !facebookResponse.ok ||
          !facebookResult.id
        ) {
          // Guardar o erro completo apenas nos logs.
          console.error(
            `Erro devolvido pelo Facebook para a divulgação ` +
              `${divulgacao.id}:`,
            JSON.stringify(facebookResult),
          );

          const detalheFacebook =
            facebookResult?.error?.message ??
            "O Facebook não confirmou a publicação.";

          throw new Error(
            `Facebook: ${detalheFacebook}`,
          );
        }

        // ----------------------------------------------------
        // 11.5. REGISTAR PUBLICAÇÃO NA FILA
        // ----------------------------------------------------

        const {
          error: atualizarErro,
        } = await supabaseAdmin
          .from("divulgacoes_redes_sociais")
          .update({
            estado: "publicado",
            mensagem,
            url_publicacao:
              `https://www.facebook.com/${facebookResult.id}`,
            data_publicacao: new Date().toISOString(),
            publicado_em: new Date().toISOString(),
            erro: null,
          })
          .eq("id", divulgacao.id);

        if (atualizarErro) {
          console.error(
            "Erro ao atualizar divulgação publicada:",
            atualizarErro,
          );

          throw new Error(
            "A publicação foi enviada ao Facebook, " +
              "mas não foi possível atualizar o registo " +
              "na tabela do Supabase.",
          );
        }

        // ----------------------------------------------------
        // 11.6. REGISTAR SUCESSO
        // ----------------------------------------------------

        resultados.push({
          id: divulgacao.id,
          obra_id: obra.id,
          estado: "publicado",
          facebook_post_id: facebookResult.id,
        });
      } catch (error) {
        // ----------------------------------------------------
        // 12. REGISTAR ERRO INDIVIDUAL
        // ----------------------------------------------------

        const erro =
          error instanceof Error
            ? error.message
            : String(error);

        console.error(
          `Erro na divulgação ${divulgacao.id}:`,
          erro,
        );

        const {
          error: atualizarErro,
        } = await supabaseAdmin
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

    // --------------------------------------------------------
    // 13. DEVOLVER RESULTADOS
    // --------------------------------------------------------

    const publicadas = resultados.filter(
      (resultado) => resultado.estado === "publicado",
    ).length;

    const falhadas = resultados.filter(
      (resultado) => resultado.estado === "erro",
    ).length;

    return respostaJSON({
      sucesso: true,
      processadas: resultados.length,
      publicadas,
      falhadas,
      resultados,
    });
  } catch (error) {
    // --------------------------------------------------------
    // 14. ERRO GERAL
    // --------------------------------------------------------

    const mensagem =
      error instanceof Error
        ? error.message
        : String(error);

    console.error(
      "Erro na divulgação Facebook:",
      mensagem,
    );

    return respostaJSON(
      {
        sucesso: false,
        erro: mensagem,
      },
      500,
    );
  }
});

