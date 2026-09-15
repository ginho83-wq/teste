import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

// Páginas
import '../pages/login_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/auth_callback_page.dart';
import '../pages/home_page.dart';
import '../pages/plataforma_page.dart';
import '../pages/minha_conta_page.dart';
import '../pages/configuracoes_page.dart';
import '../pages/publicar_obra_page.dart';
import '../pages/historico_obras_page.dart';
import '../pages/acervo_resultados_page.dart';
import '../pages/acervo_pesquisa_resultados_page.dart';
import '../pages/pesquisa_resultados_page.dart';
import '../pages/categorias_page.dart';
import '../pages/categoria_resultados_page.dart';
import '../pages/admin_obras_page.dart';
import '../pages/admin_solicitacoes_remocao_page.dart';

import '../pages/termos_page.dart';
import '../pages/politica_privacidade_page.dart';
import '../pages/cookies_page.dart';
import '../pages/contacto_page.dart';
import '../pages/ajuda_page.dart';

final AuthService _authService = AuthService.instancia;

/// Verifica se uma rota pode ser acessada sem autenticação.
///
/// As páginas de conteúdo público podem ser visitadas por qualquer pessoa.
/// As áreas pessoais e administrativas continuam protegidas.
bool _ehRotaPublica(String caminho) {
  return caminho == '/' ||
      caminho == '/plataforma' ||
      caminho == '/categorias' ||
      caminho == '/acervo' ||
      caminho == '/login' ||
      caminho == '/cadastro' ||
      caminho == '/auth/callback' ||
      caminho == '/termos' ||
      caminho == '/politica-privacidade' ||
      caminho == '/cookies' ||
      caminho == '/contacto' ||
      caminho == '/ajuda' ||
      caminho.startsWith('/categoria/') ||
      caminho.startsWith('/acervo/pesquisa/');
}

/// Router principal da aplicação.
final GoRouter router = GoRouter(
  initialLocation: '/',

  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  redirect: (
      BuildContext context,
      GoRouterState state,
      ) {
    final bool estaAutenticado =
        _authService.estaAutenticado;

    final String caminho = state.uri.path;

    final bool rotaPublica =
    _ehRotaPublica(caminho);

    // ============================================================
    // VISITANTE NÃO AUTENTICADO
    // ============================================================

    if (!estaAutenticado && !rotaPublica) {
      return '/login';
    }

    // ============================================================
    // UTILIZADOR AUTENTICADO
    // ============================================================

    if (estaAutenticado &&
        (caminho == '/login' ||
            caminho == '/cadastro')) {
      return '/';
    }

    return null;
  },

  routes: <RouteBase>[
    // ============================================================
    // AUTENTICAÇÃO
    // ============================================================

    GoRoute(
      path: '/login',
      builder: (context, state) =>
      const LoginPage(),
    ),

    GoRoute(
      path: '/cadastro',
      builder: (context, state) =>
      const CadastroPage(),
    ),

    GoRoute(
      path: '/auth/callback',
      builder: (context, state) =>
      const AuthCallbackPage(),
    ),

    // ============================================================
    // ÁREA PÚBLICA
    // ============================================================

    GoRoute(
      path: '/',
      builder: (context, state) =>
      const HomePage(),
    ),

    GoRoute(
      path: '/plataforma',
      builder: (context, state) =>
      const PlataformaPage(),
    ),

    GoRoute(
      path: '/categorias',
      builder: (context, state) =>
      const CategoriasPage(),
    ),

    GoRoute(
      path: '/categoria/:tipo',
      builder: (context, state) {
        final String tipo =
            state.pathParameters['tipo'] ?? '';

        return CategoriaResultadosPage(
          categoria: tipo,
        );
      },
    ),

    GoRoute(
      path: '/acervo',
      builder: (context, state) {
        final String? obraId =
        state.uri.queryParameters['obra'];

        return AcervoResultadosPage(
          obraId: obraId,
        );
      },
    ),

    GoRoute(
      path: '/acervo/pesquisa/:query',
      builder: (context, state) {
        final String query =
            state.pathParameters['query'] ?? '';

        return AcervoPesquisaResultadosPage(
          query: query,
        );
      },
    ),

    // ============================================================
    // PESQUISA GERAL
    // ============================================================

    GoRoute(
      path: '/search/:query',
      builder: (context, state) {
        final String query =
            state.pathParameters['query'] ?? '';

        return PesquisaResultadosPage(
          query: query,
        );
      },
    ),

    // ============================================================
    // ÁREA DO UTILIZADOR AUTENTICADO
    // ============================================================

    GoRoute(
      path: '/minha-conta',
      builder: (context, state) =>
      const MinhaContaPage(),
    ),

    GoRoute(
      path: '/configuracoes',
      builder: (context, state) =>
      const ConfiguracoesPage(),
    ),

    GoRoute(
      path: '/publicar',
      builder: (context, state) =>
      const PublicarObraPage(),
    ),

    GoRoute(
      path: '/historico-obras',
      builder: (context, state) =>
      const HistoricoObrasPage(),
    ),

    // ============================================================
    // ADMINISTRAÇÃO
    // ============================================================

    GoRoute(
      path: '/admin-obras',
      builder: (context, state) =>
      const AdminObrasPage(),
    ),

    GoRoute(
      path: '/admin-solicitacoes-remocao',
      builder: (context, state) =>
      const AdminSolicitacoesRemocaoPage(),
    ),

    // ============================================================
    // PÁGINAS INFORMATIVAS / LEGAIS
    // ============================================================

    GoRoute(
      path: '/termos',
      builder: (context, state) =>
      const TermosPage(),
    ),

    GoRoute(
      path: '/politica-privacidade',
      builder: (context, state) =>
      const PoliticaPrivacidadePage(),
    ),

    GoRoute(
      path: '/cookies',
      builder: (context, state) =>
      const CookiesPage(),
    ),

    GoRoute(
      path: '/contacto',
      builder: (context, state) =>
      const ContactoPage(),
    ),

    GoRoute(
      path: '/ajuda',
      builder: (context, state) =>
      const AjudaPage(),
    ),
  ],
);

/// Converte o stream de autenticação do Supabase
/// em Listenable para que o GoRouter reaja
/// automaticamente às alterações de sessão.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription =
        stream.asBroadcastStream().listen(
              (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic>
  _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
