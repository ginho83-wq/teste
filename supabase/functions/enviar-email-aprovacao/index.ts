import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // ==========================================================
  // CORS
  // ==========================================================

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    // ========================================================
    // 1. VERIFICAR AUTENTICAÇÃO
    // ========================================================

    const authorization =
      req.headers.get("Authorization");

    if (!authorization) {
      return new Response(
        JSON.stringify({
          error: "Utilizador não autenticado.",
        }),
        {
          status: 401,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const supabaseUrl =
      Deno.env.get("SUPABASE_URL");

    const supabaseAnonKey =
      Deno.env.get("SUPABASE_ANON_KEY");

    const serviceRoleKey =
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (
      !supabaseUrl ||
      !supabaseAnonKey ||
      !serviceRoleKey
    ) {
      console.error(
        "Variáveis do Supabase não configuradas.",
      );

      return new Response(
        JSON.stringify({
          error:
            "Configuração do Supabase incompleta.",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 2. CLIENTE COM A SESSÃO DO UTILIZADOR
    // ========================================================

    const supabaseUser = createClient(
      supabaseUrl,
      supabaseAnonKey,
      {
        global: {
          headers: {
            Authorization: authorization,
          },
        },
      },
    );

    const {
      data: { user },
      error: authError,
    } =
      await supabaseUser.auth.getUser();

    if (authError || !user) {
      console.error(
        "Erro de autenticação:",
        authError,
      );

      return new Response(
        JSON.stringify({
          error: "Sessão inválida.",
        }),
        {
          status: 401,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 3. CLIENTE ADMINISTRATIVO
    // ========================================================

    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
    );

    // ========================================================
    // 4. CONFIRMAR ADMINISTRADOR
    // ========================================================

    const {
      data: perfilAdmin,
      error: perfilAdminError,
    } = await supabaseAdmin
      .from("profiles")
      .select("id, nome, role")
      .eq("id", user.id)
      .maybeSingle();

    if (perfilAdminError) {
      console.error(
        "Erro ao verificar administrador:",
        perfilAdminError,
      );

      return new Response(
        JSON.stringify({
          error:
            "Não foi possível verificar as permissões.",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    if (
      !perfilAdmin ||
      perfilAdmin.role !== "admin"
    ) {
      return new Response(
        JSON.stringify({
          error:
            "Apenas administradores podem executar esta operação.",
        }),
        {
          status: 403,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 5. LER O ID DA OBRA
    // ========================================================

    let body;

    try {
      body = await req.json();
    } catch (_) {
      return new Response(
        JSON.stringify({
          error: "JSON inválido.",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    const obraId = body?.obra_id;

    if (
      typeof obraId !== "string" ||
      obraId.trim().length === 0
    ) {
      return new Response(
        JSON.stringify({
          error: "ID da obra inválido.",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 6. PROCURAR A OBRA PUBLICADA
    // ========================================================

    const {
      data: obra,
      error: obraError,
    } = await supabaseAdmin
      .from("obras")
      .select(
        "id, titulo, user_id",
      )
      .eq("id", obraId)
      .maybeSingle();

    if (obraError) {
      console.error(
        "Erro ao procurar obra:",
        obraError,
      );

      return new Response(
        JSON.stringify({
          error:
            "Erro ao procurar a obra publicada.",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    if (!obra) {
      return new Response(
        JSON.stringify({
          error:
            "Obra publicada não encontrada.",
        }),
        {
          status: 404,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 7. CONFIRMAR PROPRIETÁRIO
    // ========================================================

    if (!obra.user_id) {
      return new Response(
        JSON.stringify({
          error:
            "A obra não possui utilizador associado.",
        }),
        {
          status: 422,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 8. PROCURAR PERFIL DO PROPRIETÁRIO
    // ========================================================

    const {
      data: perfil,
      error: perfilError,
    } = await supabaseAdmin
      .from("profiles")
      .select("nome, email")
      .eq("id", obra.user_id)
      .maybeSingle();

    if (perfilError) {
      console.error(
        "Erro ao procurar perfil:",
        perfilError,
      );

      return new Response(
        JSON.stringify({
          error:
            "Erro ao procurar o perfil do proprietário.",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    if (!perfil) {
      return new Response(
        JSON.stringify({
          error:
            "Perfil do proprietário não encontrado.",
        }),
        {
          status: 404,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    if (
      !perfil.email ||
      perfil.email.trim().length === 0
    ) {
      return new Response(
        JSON.stringify({
          error:
            "O proprietário não possui e-mail registado.",
        }),
        {
          status: 422,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 9. CONFIGURAÇÕES DO RESEND
    // ========================================================

    const resendApiKey =
      Deno.env.get("RESEND_API_KEY");

    const emailFrom =
      Deno.env.get("EMAIL_FROM");

    const appBaseUrl =
      Deno.env.get("APP_BASE_URL") ||
      "https://ginho83-wq.github.io/teste";

    if (
      !resendApiKey ||
      !emailFrom
    ) {
      console.error(
        "RESEND_API_KEY ou EMAIL_FROM não configurado.",
      );

      return new Response(
        JSON.stringify({
          error:
            "Serviço de e-mail não está configurado.",
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 10. PREPARAR LINK DA OBRA
    // ========================================================

    const urlObra =
      `${appBaseUrl}/obra/${obra.id}`;

    const nome =
      perfil.nome?.trim() ||
      "Utilizador";

    // ========================================================
    // 11. PREPARAR HTML DO E-MAIL
    // ========================================================

    const html = `
      <!DOCTYPE html>
      <html lang="pt">
      <head>
        <meta charset="UTF-8">
        <title>A sua obra foi aprovada</title>
      </head>

      <body
        style="
          margin: 0;
          padding: 0;
          background-color: #f5f7fa;
          font-family: Arial, sans-serif;
        "
      >

        <div
          style="
            max-width: 600px;
            margin: 40px auto;
            background: #ffffff;
            border-radius: 10px;
            padding: 30px;
          "
        >

          <h1
            style="
              margin-top: 0;
              color: #1976d2;
            "
          >
            Obra Livre
          </h1>

          <h2>
            A sua obra foi aprovada
          </h2>

          <p>
            Olá ${nome},
          </p>

          <p>
            Informamos que a sua obra
            <strong>${obra.titulo}</strong>
            foi aprovada pelo administrador da
            <strong>Obra Livre</strong>.
          </p>

          <p>
            A obra foi publicada no acervo da
            Obra Livre.
          </p>

          <p
            style="
              margin: 30px 0;
            "
          >
            <a
              href="${urlObra}"
              style="
                display: inline-block;
                padding: 12px 22px;
                background-color: #1976d2;
                color: #ffffff;
                text-decoration: none;
                border-radius: 6px;
                font-weight: bold;
              "
            >
              Ver a minha obra
            </a>
          </p>

          <p>
            Obrigado por utilizar a
            <strong>Obra Livre</strong>.
          </p>

          <hr
            style="
              border: none;
              border-top: 1px solid #eeeeee;
              margin: 30px 0;
            "
          >

          <p
            style="
              color: #777777;
              font-size: 13px;
            "
          >
            Obra Livre — Acervo digital de obras
            académicas, científicas e literárias.
          </p>

        </div>

      </body>
      </html>
    `;

    // ========================================================
    // 12. ENVIAR ATRAVÉS DO RESEND
    // ========================================================

    const resendResponse =
      await fetch(
        "https://api.resend.com/emails",
        {
          method: "POST",

          headers: {
            "Authorization":
              `Bearer ${resendApiKey}`,

            "Content-Type":
              "application/json",
          },

          body: JSON.stringify({
            from: emailFrom,

            to: [
              perfil.email,
            ],

            subject:
              "A sua obra foi aprovada — Obra Livre",

            html,
          }),
        },
      );

    const resendData =
      await resendResponse.json();

    // ========================================================
    // 13. VERIFICAR RESPOSTA DO RESEND
    // ========================================================

    if (!resendResponse.ok) {
      console.error(
        "Resend recusou o envio:",
        resendData,
      );

      return new Response(
        JSON.stringify({
          error:
            "O serviço de e-mail recusou o envio.",
          details: resendData,
        }),
        {
          status: 502,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json",
          },
        },
      );
    }

    // ========================================================
    // 14. SUCESSO
    // ========================================================

    console.log(
      "E-mail de aprovação enviado:",
      {
        obra_id: obra.id,
        email: perfil.email,
      },
    );

    return new Response(
      JSON.stringify({
        success: true,
        obra_id: obra.id,
        email: perfil.email,
        resend: resendData,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  } catch (error) {
    // ========================================================
    // ERRO GERAL
    // ========================================================

    console.error(
      "Erro inesperado:",
      error,
    );

    return new Response(
      JSON.stringify({
        error:
          "Erro interno ao enviar o e-mail.",
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }
});

