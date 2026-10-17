import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json; charset=utf-8",
};

function respostaJSON(
  dados: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(dados), {
    status,
    headers: corsHeaders,
  });
}

function escaparHTML(valor: string): string {
  return valor
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function uuidValido(valor: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
    .test(valor);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return respostaJSON(
      {
        success: false,
        error: "Método não permitido.",
      },
      405,
    );
  }

  try {
    // 1. Configuração do Supabase e do Resend.

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabasePublishableKey =
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
    const serviceRoleKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const emailFrom = Deno.env.get("EMAIL_FROM");

    if (
      !supabaseUrl ||
      !supabaseAnonKey ||
      !serviceRoleKey ||
      !resendApiKey ||
      !emailFrom
    ) {
      console.error("Faltam variáveis de ambiente obrigatórias.");

      return respostaJSON(
        {
          success: false,
          error: "Configuração do serviço incompleta.",
        },
        500,
      );
    }

    // 2. Identificar o utilizador, quando existir sessão.
    // Visitantes continuam com userId = null.

    const authorization = req.headers.get("Authorization");
    let userId: string | null = null;

    if (authorization?.startsWith("Bearer ")) {
      const token = authorization.substring(7).trim();

      const chavesPublicas = [
        supabaseAnonKey,
        supabasePublishableKey,
      ].filter((key): key is string => Boolean(key));

      const tokenPublico =
        chavesPublicas.includes(token) ||
        token.startsWith("sb_publishable_");

      if (!tokenPublico) {
        const supabaseUser = createClient(
          supabaseUrl,
          supabaseAnonKey,
          {
            global: {
              headers: {
                Authorization: authorization,
              },
            },
            auth: {
              persistSession: false,
              autoRefreshToken: false,
            },
          },
        );

        const {
          data: { user },
          error,
        } = await supabaseUser.auth.getUser();

        if (error || !user) {
          console.error(
            "Falha ao validar a sessão:",
            error?.message,
          );

          return respostaJSON(
            {
              success: false,
              error: "Sessão de utilizador inválida.",
            },
            401,
          );
        }

        userId = user.id;
      }
    }

    // 3. Validar os dados recebidos.

    let body: {
      obra_id?: unknown;
      referencia?: unknown;
      formato?: unknown;
    };

    try {
      body = await req.json();
    } catch {
      return respostaJSON(
        {
          success: false,
          error: "Pedido JSON inválido.",
        },
        400,
      );
    }

    const obraId =
      typeof body.obra_id === "string"
        ? body.obra_id.trim()
        : "";

    const referencia =
      typeof body.referencia === "string"
        ? body.referencia.trim()
        : "";

    const formatoRecebido =
      typeof body.formato === "string"
        ? body.formato.trim()
        : "";

    const formatosPermitidos = [
      "APA",
      "APA 7",
      "ABNT",
      "VANCOUVER",
      "IEEE",
      "ISO 690",
      "OUTRO",
    ];

    if (!uuidValido(obraId)) {
      return respostaJSON(
        {
          success: false,
          error: "Identificador da obra inválido.",
        },
        400,
      );
    }

    if (!referencia || referencia.length > 5000) {
      return respostaJSON(
        {
          success: false,
          error: "A referência é obrigatória e deve ter até 5000 caracteres.",
        },
        400,
      );
    }

    if (!formatosPermitidos.includes(formatoRecebido)) {
      return respostaJSON(
        {
          success: false,
          error: "Formato de citação inválido.",
        },
        400,
      );
    }

    const formato =
      formatoRecebido === "APA 7"
        ? "APA"
        : formatoRecebido;

    // 4. Cliente administrativo.
    // A chave SERVICE_ROLE permanece exclusivamente no servidor.

    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    // 5. Consultar a obra.

    const {
      data: obra,
      error: erroObra,
    } = await supabaseAdmin
      .from("obras")
      .select("id, titulo, autor, user_id")
      .eq("id", obraId)
      .maybeSingle();

    if (erroObra) {
      console.error("Erro ao consultar obra:", erroObra.message);

      return respostaJSON(
        {
          success: false,
          error: "Não foi possível consultar a obra.",
        },
        500,
      );
    }

    if (!obra) {
      return respostaJSON(
        {
          success: false,
          error: "Obra não encontrada.",
        },
        404,
      );
    }

    // 6. Impedir que um utilizador autenticado cite a própria obra.

    if (userId && obra.user_id === userId) {
      return respostaJSON(
        {
          success: false,
          error: "Não é permitido citar a própria obra.",
        },
        403,
      );
    }

    // 7. Registar a citação.
    // user_id será NULL para visitantes.

    const {
      data: citacao,
      error: erroInsercao,
    } = await supabaseAdmin
      .from("citacoes_obras")
      .insert({
        obra_id: obra.id,
        user_id: userId,
        texto_citacao: referencia,
        tipo_citacao: formato,
        url_citacao: null,
      })
      .select("id")
      .single();

    if (erroInsercao || !citacao) {
      console.error(
        "Erro ao registar citação:",
        erroInsercao?.message,
      );

      return respostaJSON(
        {
          success: false,
          error: "Não foi possível registar a citação.",
        },
        500,
      );
    }

    console.log(
      `Citação ${citacao.id} registada; ` +
      `tipo de utilizador: ${userId ? "autenticado" : "visitante"}.`,
    );

    // 8. Obter o email do autor da obra.

    if (!obra.user_id) {
      return respostaJSON({
        success: true,
        citation_id: citacao.id,
        notification_sent: false,
        message:
          "Citação registada, mas a obra não tem autor associado para notificação.",
      });
    }

    const {
      data: resultadoAutor,
      error: erroAutor,
    } = await supabaseAdmin.auth.admin.getUserById(
      obra.user_id,
    );

    if (erroAutor || !resultadoAutor.user?.email) {
      console.error(
        "Email do autor indisponível:",
        erroAutor?.message,
      );

      return respostaJSON({
        success: true,
        citation_id: citacao.id,
        notification_sent: false,
        message:
          "Citação registada, mas não foi possível obter o email do autor.",
      });
    }

    // 9. Preparar a mensagem.

    const tituloObra = String(obra.titulo ?? "Obra académica");
    const nomeAutor = String(obra.autor ?? "Autor");

    const htmlEmail = `
      <!DOCTYPE html>
      <html lang="pt">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
      </head>
      <body style="font-family:Arial,sans-serif;line-height:1.6;color:#333">
        <div style="max-width:650px;margin:auto;padding:20px">
          <h2 style="color:#176B45">A sua obra foi citada!</h2>

          <p>Olá, ${escaparHTML(nomeAutor)}.</p>

          <p>
            A sua obra
            <strong>${escaparHTML(tituloObra)}</strong>
            foi utilizada para criar uma citação na plataforma Obra Livre.
          </p>

          <p>
            <strong>Formato:</strong>
            ${escaparHTML(formato)}
          </p>

          <div style="background:#f5f5f5;padding:16px;border-radius:8px">
            <strong>Referência registada:</strong>
            <p style="white-space:pre-wrap">${escaparHTML(referencia)}</p>
          </div>

          <p>
            Esta mensagem confirma o registo de uma citação na plataforma;
            não significa necessariamente que a obra tenha sido citada
            numa publicação externa.
          </p>

          <hr style="border:none;border-top:1px solid #ddd;margin:24px 0">

          <p style="font-size:13px;color:#666">
            Mensagem automática da plataforma Obra Livre.
          </p>
        </div>
      </body>
      </html>
    `;

    // 10. Enviar o email pelo Resend.

    let respostaEmail: Response;

    try {
      respostaEmail = await fetch(
        "https://api.resend.com/emails",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${resendApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: emailFrom,
            to: [resultadoAutor.user.email],
            subject: `A sua obra foi citada — ${tituloObra}`,
            html: htmlEmail,
          }),
        },
      );
    } catch (error) {
      console.error(
        "Erro de ligação ao serviço de email:",
        error instanceof Error ? error.message : String(error),
      );

      return respostaJSON({
        success: true,
        citation_id: citacao.id,
        notification_sent: false,
        message: "Citação registada, mas o serviço de email não respondeu.",
      });
    }

    if (!respostaEmail.ok) {
      const detalhe = await respostaEmail.text();

      console.error(
        "Falha no envio de email:",
        respostaEmail.status,
        detalhe,
      );

      return respostaJSON({
        success: true,
        citation_id: citacao.id,
        notification_sent: false,
        message: "Citação registada, mas o email não foi enviado.",
      });
    }

    const resultadoEmail = await respostaEmail.json();

    console.log(
      `Email enviado para o autor da obra ${obra.id}.`,
    );

    // 11. Resultado final.

    return respostaJSON({
      success: true,
      citation_id: citacao.id,
      notification_sent: true,
      notification_id: resultadoEmail.id ?? null,
      message: userId
        ? "Citação registada e autor notificado."
        : "Citação de visitante registada e autor notificado.",
    });
  } catch (error) {
    console.error(
      "Erro inesperado:",
      error instanceof Error ? error.message : String(error),
    );

    return respostaJSON(
      {
        success: false,
        error: "Erro interno ao processar a citação.",
      },
      500,
    );
  }
});

