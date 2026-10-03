import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    // ============================================================
    // 1. VERIFICAR AUTENTICAÇÃO
    // ============================================================

    const authorization = req.headers.get("Authorization");

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

    // ============================================================
    // 2. VARIÁVEIS DO SUPABASE
    // ============================================================

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

    // ============================================================
    // 3. CLIENTE SUPABASE DO UTILIZADOR
    // ============================================================

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

    // ============================================================
    // 4. CLIENTE ADMINISTRADOR
    // ============================================================

    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
    );

    // ============================================================
    // 5. VERIFICAR SE O UTILIZADOR É ADMIN
    // ============================================================

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
      console.error(
        "Tentativa de envio por utilizador que não é administrador:",
        user.id,
      );

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

    // ============================================================
    // 6. LER O BODY
    // ============================================================

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

    console.log(
      "Início do envio de e-mail de aprovação:",
      {
        obra_id: obraId,
        admin_id: user.id,
      },
    );

    // ============================================================
    // 7. PROCURAR A OBRA PUBLICADA
    // ============================================================

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
      console.error(
        "Obra publicada não encontrada:",
        obraId,
      );

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

    console.log(
      "Obra encontrada:",
      {
        obra_id: obra.id,
        titulo: obra.titulo,
        user_id: obra.user_id,
      },
    );

    // ============================================================
    // 8. VERIFICAR UTILIZADOR DA OBRA
    // ============================================================

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

    // ============================================================
    // 9. PROCURAR PERFIL DO PROPRIETÁRIO
    // ============================================================

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
      console.error(
        "Perfil do proprietário não encontrado:",
        obra.user_id,
      );

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

    // ============================================================
    // 10. VERIFICAR E-MAIL
    // ============================================================

    if (
      !perfil.email ||
      perfil.email.trim().length === 0
    ) {
      console.error(
        "O proprietário não possui e-mail:",
        obra.user_id,
      );

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

    console.log(
      "Destinatário encontrado:",
      {
        email: perfil.email,
        nome: perfil.nome,
      },
    );

    // ============================================================
    // 11. CONFIGURAÇÃO DO RESEND
    // ============================================================

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

    console.log(
      "Configuração de e-mail encontrada.",
      {
        email_from: emailFrom,
        app_base_url: appBaseUrl,
      },
    );

    // ============================================================
    // 12. URL DA OBRA
    // ============================================================

    const urlObra =
      `${appBaseUrl}/obra/${obra.id}`;

    const nome =
      perfil.nome?.trim() ||
      "Utilizador";

    // ============================================================
    // 13. HTML DO E-MAIL
    // ============================================================

    const html = `
      <!DOCTYPE html>
      <html lang="pt">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
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

    // ============================================================
    // 14. ENVIAR PARA O RESEND
    // ============================================================

    console.log(
      "A enviar e-mail para o Resend...",
      {
        to: perfil.email,
        from: emailFrom,
        obra_id: obra.id,
      },
    );

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

    // ============================================================
    // 15. LER RESPOSTA DO RESEND
    // ============================================================

    const resendData =
      await resendResponse.json();

    // ============================================================
    // 16. LOG COMPLETO DO RESEND
    // ============================================================

    console.log(
      "Resposta completa do Resend:",
      {
        http_status: resendResponse.status,
        ok: resendResponse.ok,
        data: resendData,
      },
    );

    // ============================================================
    // 17. RESEND RECUSOU
    // ============================================================

    if (!resendResponse.ok) {
      console.error(
        "Resend recusou o envio:",
        {
          status: resendResponse.status,
          data: resendData,
        },
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

    // ============================================================
    // 18. RESEND ACEITOU O E-MAIL
    // ============================================================

    console.log(
      "E-mail de aprovação aceite pelo Resend:",
      {
        obra_id: obra.id,
        email: perfil.email,
        resend: resendData,
      },
    );

    // ============================================================
    // 19. RESPOSTA FINAL
    // ============================================================

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
          "Content-Type":
            "application/json",
        },
      },
    );
  } catch (error) {
    // ============================================================
    // 20. ERRO INESPERADO
    // ============================================================

    console.error(
      "Erro inesperado ao enviar e-mail:",
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
          "Content-Type":
            "application/json",
        },
      },
    );
  }
});
