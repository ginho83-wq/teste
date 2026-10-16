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
      { error: "Método não permitido." },
      405,
    );
  }

  try {
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
        { error: "Configuração do servidor incompleta." },
        500,
      );
    }

    if (!resendApiKey || !emailFrom) {
      console.error("Configuração de e-mail incompleta.");

      return jsonResponse(
        { error: "Serviço de notificações não configurado." },
        503,
      );
    }

    const authorization = req.headers.get("Authorization");

    if (!authorization?.startsWith("Bearer ")) {
      return jsonResponse(
        { error: "Autenticação obrigatória." },
        401,
      );
    }

    // Cliente do utilizador: valida a sessão e respeita as permissões.
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
      return jsonResponse(
        { error: "Sessão inválida ou expirada." },
        401,
      );
    }

    const body = await req.json();

    const obraId = String(body.obra_id ?? "").trim();
    const referencia = String(body.referencia ?? "").trim();
    const formato = String(body.formato ?? "APA").trim();

    if (!obraId) {
      return jsonResponse(
        { error: "O identificador da obra é obrigatório." },
        400,
      );
    }

    if (!referencia || referencia.length > 5000) {
      return jsonResponse(
        { error: "A referência bibliográfica é inválida." },
        400,
      );
    }

    if (!["APA", "ABNT", "VANCOUVER", "OUTRO"].includes(formato)) {
      return jsonResponse(
        { error: "Formato bibliográfico não suportado." },
        400,
      );
    }

    // Cliente administrativo: utilizar apenas no servidor.
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

    // Obter os dados da obra citada.
    const { data: obra, error: obraError } = await supabaseAdmin
      .from("obras")
      .select("id, titulo, autor, user_id")
      .eq("id", obraId)
      .maybeSingle();

    if (obraError) {
      console.error("Erro ao consultar obra:", obraError.message);

      return jsonResponse(
        { error: "Não foi possível consultar a obra." },
        500,
      );
    }

    if (!obra) {
      return jsonResponse(
        { error: "A obra indicada não foi encontrada." },
        404,
      );
    }

    // Impedir que o autor registe a própria obra como citação recebida.
    if (obra.user_id === user.id) {
      return jsonResponse(
        {
          error:
            "Não é possível registar uma citação da própria obra.",
        },
        400,
      );
    }

    // Obter o e-mail do autor através do seu identificador.
    let emailAutor: string | null = null;

    if (obra.user_id) {
      const { data: autorUser, error: autorError } =
        await supabaseAdmin.auth.admin.getUserById(obra.user_id);

      if (autorError) {
        console.error(
          "Não foi possível consultar o autor:",
          autorError.message,
        );
      } else {
        emailAutor = autorUser.user?.email ?? null;
      }
    }

    // Registar a citação.
    // A tabela citacoes deverá conter estes campos.
    const { data: citacao, error: citacaoError } =
      await supabaseAdmin
        .from("citacoes")
        .insert({
          obra_id: obra.id,
          utilizador_id: user.id,
          referencia,
          formato,
        })
        .select("id")
        .single();

    if (citacaoError) {
      console.error(
        "Erro ao registar citação:",
        citacaoError.message,
      );

      return jsonResponse(
        {
          error:
            "Não foi possível registar a citação. Verifique a tabela e as respetivas permissões.",
        },
        500,
      );
    }

    // A citação fica registada mesmo que não seja possível enviar o e-mail.
    if (!emailAutor) {
      return jsonResponse({
        success: true,
        notification_sent: false,
        message: "Citação registada, mas não foi possível obter o e-mail do autor.",
        citation_id: citacao.id,
      });
    }

    const siteUrl = Deno.env.get("SITE_URL") ??
      "https://ginho83-wq.github.io/teste/";

    const obraUrl =
      `${siteUrl.replace(/\/+$/, "")}/obra/${encodeURIComponent(obra.id)}`;

    const emailResponse = await fetch(
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

    if (!emailResponse.ok) {
      const emailError = await emailResponse.text();

      console.error("Erro do Resend:", emailError);

      return jsonResponse({
        success: true,
        notification_sent: false,
        message:
          "Citação registada, mas o envio da notificação falhou.",
        citation_id: citacao.id,
      });
    }

    return jsonResponse({
      success: true,
      notification_sent: true,
      message: "Citação registada e autor notificado.",
      citation_id: citacao.id,
    });
  } catch (error) {
    console.error("Erro inesperado:", error);

    return jsonResponse(
      { error: "Ocorreu um erro interno ao processar a citação." },
      500,
    );
  }
});

