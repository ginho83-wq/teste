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
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/minha_conta_page.dart';
import '../pages/politica_privacidade_page.dart';
import '../pages/publicar_obra_page.dart';
import '../pages/termos_page.dart';
import '../pages/cookies_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',

  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
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

    if (!estaAutenticado && !rotaPublica) {
      return '/login';
    }

    if (estaAutenticado &&
        (caminho == '/login' || caminho == '/cadastro')) {
      return '/';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: '/cadastro',
      builder: (context, state) => const CadastroPage(),
    ),

    GoRoute(
      path: '/auth/callback',
      builder: (context, state) => const AuthCallbackPage(),
    ),

    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),

    GoRoute(
      path: '/minha-conta',
      builder: (context, state) => const MinhaContaPage(),
    ),

    GoRoute(
      path: '/configuracoes',
      builder: (context, state) => const ConfiguracoesPage(),
    ),

    GoRoute(
      path: '/publicar',
      builder: (context, state) => const PublicarObraPage(),
    ),

    GoRoute(
      path: '/acervo',
      builder: (context, state) => const AcervoResultadosPage(),
    ),

    GoRoute(
      path: '/search/:query',
      builder: (context, state) {
        final query = state.pathParameters['query'] ?? '';

        return AcervoResultadosPage(
          query: query,
        );
      },
    ),

    GoRoute(
      path: '/categoria/:tipo',
      builder: (context, state) {
        final categoria = state.pathParameters['tipo'] ?? '';

        return AcervoResultadosPage(
          categoria: categoria,
        );
      },
    ),

    GoRoute(
      path: '/admin-obras',
      builder: (context, state) => const AdminObrasPage(),
    ),

    GoRoute(
      path: '/termos',
      builder: (context, state) => const TermosPage(),
    ),

    GoRoute(
      path: '/politica-privacidade',
      builder: (context, state) => const PoliticaPrivacidadePage(),
    ),

    GoRoute(
      path: '/cookies',
      builder: (context, state) => const CookiesPage(),
    ),

    GoRoute(
      path: '/contacto',
      builder: (context, state) => const ContactoPage(),
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
          (_) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
