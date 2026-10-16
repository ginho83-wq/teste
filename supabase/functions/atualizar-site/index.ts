import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods":
    "POST, OPTIONS",
};

Deno.serve(async (req) => {
  // ============================================================
  // 1. Permitir requisições OPTIONS
  // ============================================================

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  // ============================================================
  // 2. Aceitar somente POST
  // ============================================================

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({
        success: false,
        error: "Método não permitido.",
      }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }

  try {
    // ============================================================
    // 3. Obter configurações do Supabase
    // ============================================================

    const supabaseUrl =
      Deno.env.get("SUPABASE_URL");

    const supabaseAnonKey =
      Deno.env.get("SUPABASE_ANON_KEY");

    const githubToken =
      Deno.env.get("GITHUB_TOKEN");

    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error(
        "Configuração do Supabase não encontrada.",
      );
    }

    if (!githubToken) {
      throw new Error(
        "O secret GITHUB_TOKEN não está configurado.",
      );
    }

    // ============================================================
    // 4. Verificar autenticação
    // ============================================================

    const authorization =
      req.headers.get("Authorization");

    if (!authorization) {
      return new Response(
        JSON.stringify({
          success: false,
          error:
            "Sessão de utilizador não encontrada.",
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

    const supabase = createClient(
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

    // ============================================================
    // 5. Obter utilizador autenticado
    // ============================================================

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          success: false,
          error:
            "Utilizador não autenticado.",
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
    // 6. Confirmar que é administrador
    // ============================================================

    const {
      data: profile,
      error: profileError,
    } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    if (profileError) {
      console.error(
        "Erro ao consultar perfil:",
        profileError,
      );

      throw new Error(
        "Não foi possível verificar o perfil do utilizador.",
      );
    }

    if (!profile || profile.role !== "admin") {
      return new Response(
        JSON.stringify({
          success: false,
          error:
            "Acesso reservado ao administrador.",
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
    // 7. Disparar o GitHub Actions
    // ============================================================

    const githubUrl =
      "https://api.github.com/repos/" +
      "ginho83-wq/teste/actions/workflows/" +
      "deploy.yml/dispatches";

    const githubResponse = await fetch(
      githubUrl,
      {
        method: "POST",

        headers: {
          "Accept":
            "application/vnd.github+json",

          "Authorization":
            `Bearer ${githubToken}`,

          "X-GitHub-Api-Version":
            "2026-03-10",

          "Content-Type":
            "application/json",

          "User-Agent":
            "Obra-Livre-Supabase-Edge-Function",
        },

        body: JSON.stringify({
          ref: "main",
        }),
      },
    );

    // ============================================================
    // 8. Verificar resposta do GitHub
    // ============================================================

    if (!githubResponse.ok) {
      const githubBody =
        await githubResponse.text();

      console.error(
        "Erro ao iniciar GitHub Actions:",
        githubResponse.status,
        githubBody,
      );

      throw new Error(
        `GitHub Actions respondeu com HTTP ` +
        `${githubResponse.status}.`,
      );
    }

    // ============================================================
    // 9. Sucesso
    // ============================================================

    console.log(
      `GitHub Actions iniciado pelo administrador ` +
      `${user.id}.`,
    );

    return new Response(
      JSON.stringify({
        success: true,
        message:
          "Atualização do site iniciada com sucesso.",
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
    console.error(
      "Erro na Edge Function:",
      error,
    );

    return new Response(
      JSON.stringify({
        success: false,
        error:
          error instanceof Error
            ? error.message
            : "Erro interno.",
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
