import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonResponse = (
  data: Record<string, unknown>,
  status = 200,
) => {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse(
      { success: false, error: "Método não permitido." },
      405,
    );
  }

  try {
    // --------------------------------------------------
    // 1. Configuração do servidor
    // --------------------------------------------------

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = Deno.env.get(
      "SUPABASE_SERVICE_ROLE_KEY",
    );

    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const emailFrom = Deno.env.get("EMAIL_FROM");

    if (
      !supabaseUrl ||
      !supabaseAnonKey ||
      !supabaseServiceRoleKey
    ) {
      console.error("Configuração do Supabase incompleta.");

      return jsonResponse(
        {
          success: false,
          error: "Configuração do servidor incompleta.",
        },
        500,
      );
    }

    if (!resendApiKey || !emailFrom) {
      console.error("Configuração de email incompleta.");

      return jsonResponse(
        {
          success: false,
          error: "Serviço de notificações não configurado.",
        },
        503,
      );
    }

    // --------------------------------------------------
    // 2. Validar a sessão do utilizador
    // --------------------------------------------------

    const authorization = req.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(
        {
          success: false,
          error: "Autenticação obrigatória.",
        },
        401,
      );
    }

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
      error: userError,
    } = await supabaseUser.auth.getUser();

    if (userError || !user) {
      console.error(
        "Falha na validação da sessão:",
        userError?.message ?? "Utilizador não encontrado.",
      );

      return jsonResponse(
        {
          success: false,
          error: "Sessão inválida ou expirada.",
        },
        401,
      );
    }

    // --------------------------------------------------
    // 3. Ler e validar os dados recebidos
    // --------------------------------------------------

    let body: Record<string, unknown>;

    try {
      const dadosRecebidos: unknown = await req.json();

      if (
        dadosRecebidos === null ||
        typeof dadosRecebidos !== "object" ||
        Array.isArray(dadosRecebidos)
      ) {
        return jsonResponse(
          {
            success: false,
            error: "O corpo do pedido deve ser um objeto JSON.",
          },
          400,
        );
      }

      body = dadosRecebidos as Record<string, unknown>;
    } catch {
      return jsonResponse(
        {
          success: false,
          error: "O corpo do pedido contém JSON inválido.",
        },
        400,
      );
    }

    const obraId = String(body.obra_id ?? "").trim();
    const referencia = String(body.referencia ?? "").trim();
    const formato = String(body.formato ?? "APA").trim().toUpperCase();

    // Diagnóstico: não registar o texto completo da citação.
    console.log(
      "DEBUG CITAÇÃO:",
      JSON.stringify({
        obraId,
        referenciaPresente: referencia.length > 0,
        referenciaTamanho: referencia.length,
        formato,
        utilizadorId: user.id,
      }),
    );

    if (!obraId) {
      console.error("Validação falhou: obra_id vazio.");

      return jsonResponse(
        {
          success: false,
          error: "O identificador da obra é obrigatório.",
          code: "OBRA_ID_VAZIO",
        },
        400,
      );
    }

    // Validar o formato UUID do identificador.
    const formatoUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

    if (!formatoUuid.test(obraId)) {
      console.error("Validação falhou: obra_id não é um UUID válido.");

      return jsonResponse(
        {
          success: false,
          error: "O identificador da obra é inválido.",
          code: "OBRA_ID_INVALIDO",
        },
        400,
      );
    }

    if (!referencia || referencia.length > 5000) {
      console.error(
        "Validação falhou: referência vazia ou demasiado longa.",
      );

      return jsonResponse(
        {
          success: false,
          error:
            "A referência bibliográfica está vazia ou ultrapassa 5.000 caracteres.",
          code: "REFERENCIA_INVALIDA",
        },
        400,
      );
    }

    const formatosAceites = [
      "APA",
      "ABNT",
      "VANCOUVER",
      "IEEE",
      "ISO 690",
      "OUTRO",
    ];

    if (!formatosAceites.includes(formato)) {
      console.error("Validação falhou: formato não suportado.", formato);

      return jsonResponse(
        {
          success: false,
          error: "Formato bibliográfico não suportado.",
          code: "FORMATO_INVALIDO",
          formatos_aceites: formatosAceites,
        },
        400,
      );
    }

    // --------------------------------------------------
    // 4. Criar cliente administrativo
    // --------------------------------------------------

    const supabaseAdmin = createClient(
      supabaseUrl,
      supabaseServiceRoleKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    // --------------------------------------------------
    // 5. Consultar a obra
    // --------------------------------------------------

    const {
      data: obra,
      error: obraError,
    } = await supabaseAdmin
      .from("obras")
      .select("id, titulo, autor, user_id")
      .eq("id", obraId)
      .maybeSingle();

    if (obraError) {
      console.error(
        "Erro ao consultar a obra:",
        obraError.message,
      );

      return jsonResponse(
        {
          success: false,
          error: "Não foi possível consultar a obra.",
        },
        500,
      );
    }

    if (!obra) {
      console.error("Obra não encontrada:", obraId);

      return jsonResponse(
        {
          success: false,
          error: "A obra indicada não foi encontrada.",
          code: "OBRA_NAO_ENCONTRADA",
        },
        404,
      );
    }

    // --------------------------------------------------
    // 6. Impedir que o autor cite a própria obra
    // --------------------------------------------------

    if (obra.user_id && obra.user_id === user.id) {
      console.warn(
        "Citação própria rejeitada.",
        JSON.stringify({
          obraId: obra.id,
          utilizadorId: user.id,
        }),
      );

      return jsonResponse(
        {
          success: false,
          error:
            "Não é possível registar uma citação da própria obra.",
          code: "CITACAO_PROPRIA",
        },
        400,
      );
    }

    // --------------------------------------------------
    // 7. Obter o email do autor
    // --------------------------------------------------

    let emailAutor: string | null = null;

    if (obra.user_id) {
      const {
        data: autorUser,
        error: autorError,
      } = await supabaseAdmin.auth.admin.getUserById(
        obra.user_id,
      );

      if (autorError) {
        console.error(
          "Não foi possível consultar o email do autor:",
          autorError.message,
        );
      } else {
        emailAutor = autorUser.user?.email ?? null;
      }
    }

    // --------------------------------------------------
    // 8. Registar a citação nas colunas reais da tabela
    // --------------------------------------------------

    const {
      data: citacao,
      error: citacaoError,
    } = await supabaseAdmin
      .from("citacoes_obras")
      .insert({
        obra_id: obra.id,
        user_id: user.id,
        texto_citacao: referencia,
        tipo_citacao: formato,
        url_citacao: null,
      })
      .select("id")
      .single();

    if (citacaoError) {
      console.error(
        "Erro ao registar citação:",
        JSON.stringify({
          message: citacaoError.message,
          code: citacaoError.code,
          details: citacaoError.details,
          hint: citacaoError.hint,
        }),
      );

      return jsonResponse(
        {
          success: false,
          error: "Não foi possível registar a citação.",
          details: citacaoError.message,
        },
        500,
      );
    }

    console.log(
      "Citação registada:",
      JSON.stringify({
        citationId: citacao.id,
        obraId: obra.id,
      }),
    );

    // --------------------------------------------------
    // 9. Se não existir email do autor, manter o registo
    // --------------------------------------------------

    if (!emailAutor) {
      console.warn(
        "Citação registada, mas não foi encontrado email do autor.",
        JSON.stringify({
          obraId: obra.id,
          citationId: citacao.id,
        }),
      );

      return jsonResponse({
        success: true,
        notification_sent: false,
        message:
          "Citação registada, mas não foi possível obter o email do autor.",
        citation_id: citacao.id,
      });
    }

    // --------------------------------------------------
    // 10. Preparar o endereço da obra
    // --------------------------------------------------

    const siteUrl = (
      Deno.env.get("SITE_URL") ??
      "https://ginho83-wq.github.io/teste/"
    ).replace(/\/+$/, "");

    const obraUrl =
      `${siteUrl}/obra/${encodeURIComponent(obra.id)}`;

    // --------------------------------------------------
    // 11. Enviar email através do Resend
    // --------------------------------------------------

    let emailResponse: Response;

    try {
      emailResponse = await fetch(
        "https://api.resend.com/emails",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${resendApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: emailFrom,
            to: [emailAutor],
            subject: "A tua obra foi citada — Obra Livre",
            text: [
              `Olá${obra.autor ? ` ${obra.autor}` : ""},`,
              "",
              "Uma obra publicada por ti na plataforma Obra Livre foi citada.",
              "",
              `Obra: ${obra.titulo}`,
              `Formato bibliográfico: ${formato}`,
              "",
              "Referência bibliográfica registada:",
              referencia,
              "",
              `Consultar a obra: ${obraUrl}`,
              "",
              "Esta é uma notificação automática da plataforma Obra Livre.",
            ].join("\n"),
          }),
        },
      );
    } catch (emailErro) {
      console.error(
        "Falha de ligação ao serviço Resend:",
        emailErro instanceof Error
          ? emailErro.message
          : String(emailErro),
      );

      return jsonResponse({
        success: true,
        notification_sent: false,
        message:
          "Citação registada, mas não foi possível contactar o serviço de email.",
        citation_id: citacao.id,
      });
    }

    if (!emailResponse.ok) {
      const emailError = await emailResponse.text();

      console.error(
        "Erro devolvido pelo Resend:",
        JSON.stringify({
          status: emailResponse.status,
          response: emailError,
        }),
      );

      return jsonResponse({
        success: true,
        notification_sent: false,
        message:
          "Citação registada, mas o serviço de email não confirmou o envio.",
        citation_id: citacao.id,
      });
    }

    // --------------------------------------------------
    // 12. Sucesso
    // --------------------------------------------------

    console.log(
      "Notificação enviada ao serviço de email.",
      JSON.stringify({
        obraId: obra.id,
        citationId: citacao.id,
      }),
    );

    return jsonResponse({
      success: true,
      notification_sent: true,
      message: "Citação registada e email enviado ao serviço de email.",
      citation_id: citacao.id,
    });
  } catch (error) {
    console.error(
      "Erro inesperado na função:",
      error instanceof Error
        ? error.message
        : String(error),
    );

    return jsonResponse(
      {
        success: false,
        error: "Ocorreu um erro interno ao processar a citação.",
      },
      500,
    );
  }
});

