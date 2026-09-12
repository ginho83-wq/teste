import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/acervo_resultados_page.dart';
import '../pages/admin_obras_page.dart';
import '../pages/auth_callback_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/contacto_page.dart';
import '../pages/configuracoes_page.dart';
import '../pages/cookies_page.dart';
import '../pages/home_page.dart';
import '../pages/historico_obras_page.dart';
import '../pages/login_page.dart';
import '../pages/minha_conta_page.dart';
import '../pages/politica_privacidade_page.dart';
import '../pages/publicar_obra_page.dart';
import '../pages/termos_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

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

    const rotasPublicas = <String>{
      '/login',
      '/cadastro',
      '/auth/callback',
      '/termos',
      '/politica-privacidade',
      '/cookies',
      '/contacto',
    };

    final rotaPublica = rotasPublicas.contains(caminho);

    // Se não estiver autenticado, só pode acessar
    // as rotas públicas.
    if (!estaAutenticado && !rotaPublica) {
      return '/login';
    }

    // Se já estiver autenticado e tentar voltar
    // para login ou cadastro, vai para a Home.
    if (estaAutenticado &&
        (caminho == '/login' ||
            caminho == '/cadastro')) {
      return '/';
    }

    return null;
  },

  routes: [
    // =====================================================
    // LOGIN
    // =====================================================
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    ),

    // =====================================================
    // CADASTRO
    // =====================================================
    GoRoute(
      path: '/cadastro',
      builder: (context, state) {
        return const CadastroPage();
      },
    ),

    // =====================================================
    // CALLBACK DE AUTENTICAÇÃO
    // =====================================================
    GoRoute(
      path: '/auth/callback',
      builder: (context, state) {
        return const AuthCallbackPage();
      },
    ),

    // =====================================================
    // HOME
    // =====================================================
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomePage();
      },
    ),

    // =====================================================
    // MINHA CONTA
    // =====================================================
    GoRoute(
      path: '/minha-conta',
      builder: (context, state) {
        return const MinhaContaPage();
      },
    ),

    // =====================================================
    // CONFIGURAÇÕES
    // =====================================================
    GoRoute(
      path: '/configuracoes',
      builder: (context, state) {
        return const ConfiguracoesPage();
      },
    ),

    // =====================================================
    // PUBLICAR OBRA
    // =====================================================
    GoRoute(
      path: '/publicar',
      builder: (context, state) {
        return const PublicarObraPage();
      },
    ),

    // =====================================================
    // HISTÓRICO DE OBRAS CONSULTADAS
    // =====================================================
    GoRoute(
      path: '/historico-obras',
      builder: (context, state) {
        return const HistoricoObrasPage();
      },
    ),

    // =====================================================
    // ACERVO
    // =====================================================
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

    // =====================================================
    // PESQUISA
    // =====================================================
    GoRoute(
      path: '/search/:query',
      builder: (context, state) {
        final query =
            state.pathParameters['query'] ?? '';

        return AcervoResultadosPage(
          query: query,
        );
      },
    ),

    // =====================================================
    // CATEGORIA
    // =====================================================
    GoRoute(
      path: '/categoria/:tipo',
      builder: (context, state) {
        final categoria =
            state.pathParameters['tipo'] ?? '';

        return AcervoResultadosPage(
          categoria: categoria,
        );
      },
    ),

    // =====================================================
    // ADMINISTRAÇÃO
    // =====================================================
    GoRoute(
      path: '/admin-obras',
      builder: (context, state) {
        return const AdminObrasPage();
      },
    ),

    // =====================================================
    // TERMOS
    // =====================================================
    GoRoute(
      path: '/termos',
      builder: (context, state) {
        return const TermosPage();
      },
    ),

    // =====================================================
    // POLÍTICA DE PRIVACIDADE
    // =====================================================
    GoRoute(
      path: '/politica-privacidade',
      builder: (context, state) {
        return const PoliticaPrivacidadePage();
      },
    ),

    // =====================================================
    // COOKIES
    // =====================================================
    GoRoute(
      path: '/cookies',
      builder: (context, state) {
        return const CookiesPage();
      },
    ),

    // =====================================================
    // CONTACTO
    // =====================================================
    GoRoute(
      path: '/contacto',
      builder: (context, state) {
        return const ContactoPage();
      },
    ),
  ],
);
