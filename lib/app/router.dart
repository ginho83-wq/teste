import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/acervo_resultados_page.dart';
import '../pages/admin_obras_page.dart';
import '../pages/admin_solicitacoes_remocao_page.dart';
import '../pages/ajuda_page.dart';
import '../pages/auth_callback_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/categorias_page.dart';
import '../pages/configuracoes_page.dart';
import '../pages/contacto_page.dart';
import '../pages/cookies_page.dart';
import '../pages/home_page.dart';
import '../pages/historico_obras_page.dart';
import '../pages/login_page.dart';
import '../pages/minha_conta_page.dart';
import '../pages/politica_privacidade_page.dart';
import '../pages/publicar_obra_page.dart';
import '../pages/termos_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
          (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/login',

  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  redirect: (context, state) {
    final session =
        Supabase.instance.client.auth.currentSession;

    final estaAutenticado = session != null;

    final caminho = state.uri.path;

    const rotasPublicas = {
      '/login',
      '/cadastro',
      '/auth/callback',
      '/termos',
      '/politica-privacidade',
      '/cookies',
      '/contacto',
      '/ajuda',
    };

    final ehRotaPublica =
    rotasPublicas.contains(caminho);

    // Utilizador não autenticado:
    // só pode acessar as páginas públicas.
    if (!estaAutenticado && !ehRotaPublica) {
      return '/login';
    }

    // Utilizador autenticado não precisa
    // voltar para login ou cadastro.
    if (estaAutenticado &&
        (caminho == '/login' ||
            caminho == '/cadastro')) {
      return '/';
    }

    return null;
  },

  routes: [
    // =========================================================
    // AUTENTICAÇÃO
    // =========================================================

    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    ),

    GoRoute(
      path: '/cadastro',
      builder: (context, state) {
        return const CadastroPage();
      },
    ),

    GoRoute(
      path: '/auth/callback',
      builder: (context, state) {
        return const AuthCallbackPage();
      },
    ),

    // =========================================================
    // PÁGINAS PRINCIPAIS
    // =========================================================

    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomePage();
      },
    ),

    GoRoute(
      path: '/categorias',
      builder: (context, state) {
        return const CategoriasPage();
      },
    ),

    GoRoute(
      path: '/acervo',
      builder: (context, state) {
        final obraId =
        state.uri.queryParameters['obra'];

        return AcervoResultadosPage(
          obraId: obraId,
        );
      },
    ),

    GoRoute(
      path: '/search/:query',
      builder: (context, state) {
        final query =
        state.pathParameters['query'];

        return AcervoResultadosPage(
          query: query,
        );
      },
    ),

    GoRoute(
      path: '/categoria/:tipo',
      builder: (context, state) {
        final categoria =
        state.pathParameters['tipo'];

        return AcervoResultadosPage(
          categoria: categoria,
        );
      },
    ),

    // =========================================================
    // CONTA DO UTILIZADOR
    // =========================================================

    GoRoute(
      path: '/minha-conta',
      builder: (context, state) {
        return const MinhaContaPage();
      },
    ),

    GoRoute(
      path: '/configuracoes',
      builder: (context, state) {
        return const ConfiguracoesPage();
      },
    ),

    // =========================================================
    // PUBLICAR
    // =========================================================

    GoRoute(
      path: '/publicar',
      builder: (context, state) {
        return const PublicarObraPage();
      },
    ),

    // =========================================================
    // HISTÓRICO
    // =========================================================

    GoRoute(
      path: '/historico-obras',
      builder: (context, state) {
        return const HistoricoObrasPage();
      },
    ),

    // =========================================================
    // ADMINISTRAÇÃO
    // =========================================================

    GoRoute(
      path: '/admin-obras',
      builder: (context, state) {
        return const AdminObrasPage();
      },
    ),

    GoRoute(
      path: '/admin-solicitacoes-remocao',
      builder: (context, state) {
        return const AdminSolicitacoesRemocaoPage();
      },
    ),

    // =========================================================
    // PÁGINAS INFORMATIVAS
    // =========================================================

    GoRoute(
      path: '/termos',
      builder: (context, state) {
        return const TermosPage();
      },
    ),

    GoRoute(
      path: '/politica-privacidade',
      builder: (context, state) {
        return const PoliticaPrivacidadePage();
      },
    ),

    GoRoute(
      path: '/cookies',
      builder: (context, state) {
        return const CookiesPage();
      },
    ),

    GoRoute(
      path: '/contacto',
      builder: (context, state) {
        return const ContactoPage();
      },
    ),

    GoRoute(
      path: '/ajuda',
      builder: (context, state) {
        return const AjudaPage();
      },
    ),
  ],
);
