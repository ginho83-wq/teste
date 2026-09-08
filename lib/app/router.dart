
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/cadastro_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/auth_callback_page.dart';

// ================================================================
// ROUTER PRINCIPAL
// ================================================================

final GoRouter appRouter = GoRouter(
  // ==============================================================
  // PRIMEIRA TELA
  // ==============================================================

  initialLocation: '/login',

  // ==============================================================
  // ATUALIZA O ROUTER QUANDO O ESTADO DA AUTENTICAÇÃO MUDA
  // ==============================================================

  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),

  // ==============================================================
  // CONTROLE DE ACESSO
  // ==============================================================

  redirect: (context, state) {
    final session =
        Supabase.instance.client.auth.currentSession;

    final location = state.matchedLocation;

    final estaNoLogin = location == '/login';
    final estaNoCadastro = location == '/cadastro';
    final estaNoCallback = location == '/auth/callback';

    // ============================================================
    // CALLBACK DO SUPABASE
    // ============================================================

    if (estaNoCallback) {
      return null;
    }

    // ============================================================
    // UTILIZADOR NÃO AUTENTICADO
    // ============================================================

    if (session == null) {
      if (estaNoLogin || estaNoCadastro) {
        return null;
      }

      return '/login';
    }

    // ============================================================
    // UTILIZADOR AUTENTICADO
    // ============================================================

    if (estaNoLogin || estaNoCadastro) {
      return '/home';
    }

    return null;
  },

  // ==============================================================
  // ROTAS
  // ==============================================================

  routes: [
    // ============================================================
    // LOGIN
    // ============================================================

    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    ),

    // ============================================================
    // CADASTRO
    // ============================================================

    GoRoute(
      path: '/cadastro',
      builder: (context, state) {
        return const CadastroPage();
      },
    ),

    // ============================================================
    // CALLBACK DO SUPABASE
    // ============================================================

    GoRoute(
      path: '/auth/callback',
      builder: (context, state) {
        return const AuthCallbackPage();
      },
    ),

    // ============================================================
    // HOME
    // ============================================================

    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomePage();
      },
    ),
  ],
);

// ================================================================
// ATUALIZAÇÃO DO GO_ROUTER
// ================================================================

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
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

