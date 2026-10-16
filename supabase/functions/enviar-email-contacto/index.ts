import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function resposta(
  body: Record<string, unknown>,
  status = 200,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return resposta(
      {
        success: false,
        error: "Método não permitido.",
      },
      405,
    );
  }

  try {
    const body = await req.json();

    const nome =
      typeof body?.nome === "string"
        ? body.nome.trim()
        : "";

    const email =
      typeof body?.email === "string"
        ? body.email.trim()
        : "";

    const assunto =
      typeof body?.assunto === "string"
        ? body.assunto.trim()
        : "";

    const mensagem =
      typeof body?.mensagem === "string"
        ? body.mensagem.trim()
        : "";

    if (!nome || !email || !assunto || !mensagem) {
      return resposta(
        {
          success: false,
          error: "Todos os campos são obrigatórios.",
        },
        400,
      );
    }

    const emailValido =
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

    if (!emailValido) {
      return resposta(
        {
          success: false,
          error: "O email informado é inválido.",
        },
        400,
      );
    }

    if (nome.length > 150) {
      return resposta(
        {
          success: false,
          error: "O nome é demasiado longo.",
        },
        400,
      );
    }

    if (email.length > 254) {
      return resposta(
        {
          success: false,
          error: "O email é demasiado longo.",
        },
        400,
      );
    }

    if (assunto.length > 200) {
      return resposta(
        {
          success: false,
          error: "O assunto é demasiado longo.",
        },
        400,
      );
    }

    if (mensagem.length > 5000) {
      return resposta(
        {
          success: false,
          error: "A mensagem é demasiado longa.",
        },
        400,
      );
    }

    const resendApiKey =
      Deno.env.get("RESEND_API_KEY");

    const emailFrom =
      Deno.env.get("EMAIL_FROM");

    if (!resendApiKey) {
      console.error(
        "RESEND_API_KEY não configurada.",
      );

      return resposta(
        {
          success: false,
          error: "Serviço de email não configurado.",
        },
        500,
      );
    }

    if (!emailFrom) {
      console.error(
        "EMAIL_FROM não configurado.",
      );

      return resposta(
        {
          success: false,
          error: "Remetente de email não configurado.",
        },
        500,
      );
    }

    const nomeSeguro = escapeHtml(nome);
    const emailSeguro = escapeHtml(email);
    const assuntoSeguro = escapeHtml(assunto);

    const mensagemSegura =
      escapeHtml(mensagem).replace(
        /\n/g,
        "<br>",
      );

    const html = `
      <!DOCTYPE html>
      <html lang="pt">
      <head>
        <meta charset="UTF-8">
        <title>Nova mensagem — Obra Livre</title>
      </head>

      <body style="
        margin: 0;
        padding: 0;
        background-color: #f4f7fb;
        font-family: Arial, Helvetica, sans-serif;
      ">

        <div style="
          max-width: 700px;
          margin: 30px auto;
          background: #ffffff;
          border-radius: 12px;
          overflow: hidden;
          border: 1px solid #e1e8f0;
        ">

          <div style="
            background-color: #eaf4ff;
            padding: 24px;
            border-bottom: 1px solid #d5e5f5;
          ">

            <h2 style="
              margin: 0;
              color: #1f4f7a;
            ">
              Nova mensagem — Obra Livre
            </h2>

          </div>

          <div style="padding: 28px;">

            <p style="margin-top: 0;">
              Foi recebida uma nova mensagem através
              do formulário de contacto/publicidade
              do <strong>Obra Livre</strong>.
            </p>

            <table style="
              width: 100%;
              border-collapse: collapse;
              margin-top: 20px;
            ">

              <tr>
                <td style="
                  padding: 10px;
                  font-weight: bold;
                  width: 120px;
                  border-bottom: 1px solid #eeeeee;
                ">
                  Nome
                </td>

                <td style="
                  padding: 10px;
                  border-bottom: 1px solid #eeeeee;
                ">
                  ${nomeSeguro}
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 10px;
                  font-weight: bold;
                  border-bottom: 1px solid #eeeeee;
                ">
                  Email
                </td>

                <td style="
                  padding: 10px;
                  border-bottom: 1px solid #eeeeee;
                ">
                  ${emailSeguro}
                </td>
              </tr>

              <tr>
                <td style="
                  padding: 10px;
                  font-weight: bold;
                  border-bottom: 1px solid #eeeeee;
                ">
                  Assunto
                </td>

                <td style="
                  padding: 10px;
                  border-bottom: 1px solid #eeeeee;
                ">
                  ${assuntoSeguro}
                </td>
              </tr>

            </table>

            <div style="
              margin-top: 25px;
              padding: 18px;
              background-color: #f8fafc;
              border-radius: 8px;
            ">

              <strong>Mensagem:</strong>

              <p style="
                line-height: 1.6;
                margin-bottom: 0;
              ">
                ${mensagemSegura}
              </p>

            </div>

          </div>

          <div style="
            padding: 18px 24px;
            background-color: #f8fafc;
            color: #6b7280;
            font-size: 12px;
          ">
            Mensagem enviada através do formulário
            de contacto do Obra Livre.
          </div>

        </div>

      </body>
      </html>
    `;

    console.log(
      "Enviando mensagem de contacto...",
    );

    const resendResponse = await fetch(
      "https://api.resend.com/emails",
      {
        method: "POST",

        headers: {
          Authorization:
            `Bearer ${resendApiKey}`,

          "Content-Type":
            "application/json",
        },

        body: JSON.stringify({
          from: emailFrom,

          to: [
            "ginho83@gmail.com",
          ],

          reply_to: email,

          subject:
            `Publicidade — ${assunto}`,

          html,
        }),
      },
    );

    const resendData =
      await resendResponse.json();

    if (!resendResponse.ok) {
      console.error(
        "Erro da Resend:",
        resendData,
      );

      return resposta(
        {
          success: false,
          error:
            "Não foi possível enviar o email.",
        },
        502,
      );
    }

    console.log(
      "Email enviado com sucesso:",
      resendData,
    );

    return resposta({
      success: true,
      message:
        "Mensagem enviada com sucesso.",
    });

  } catch (error) {
    console.error(
      "Erro interno:",
      error,
    );

    return resposta(
      {
        success: false,
        error:
          "Erro interno ao processar a mensagem.",
      },
      500,
    );
  }
});
