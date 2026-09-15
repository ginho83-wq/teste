import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

import '../pages/login_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/auth_callback_page.dart';
import '../pages/home_page.dart';
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

final AuthService _authService =
    AuthService.instancia;

final GoRouter router = GoRouter(
  initialLocation: '/login',

  refreshListenable:
  GoRouterRefreshStream(
    Supabase
        .instance
        .client
        .auth
        .onAuthStateChange,
  ),

  redirect: (context, state) {
    final estaAutenticado =
        _authService.estaAutenticado;

    final caminho =
        state.uri.path;

    final rotasPublicas =
    <String>{
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
    rotasPublicas.contains(
      caminho,
    );

    if (!estaAutenticado &&
        !ehRotaPublica) {
      return '/login';
    }

    if (estaAutenticado &&
        (caminho == '/login' ||
            caminho == '/cadastro')) {
      return '/';
    }

    return null;
  },

  routes: [
    // ============================================================
    // LOGIN
    // ============================================================

    GoRoute(
      path: '/login',
      builder: (context, state) =>
      const LoginPage(),
    ),

    // ============================================================
    // CADASTRO
    // ============================================================

    GoRoute(
      path: '/cadastro',
      builder: (context, state) =>
      const CadastroPage(),
    ),

    // ============================================================
    // CALLBACK AUTENTICAÇÃO
    // ============================================================

    GoRoute(
      path: '/auth/callback',
      builder: (context, state) =>
      const AuthCallbackPage(),
    ),

    // ============================================================
    // HOME
    // ============================================================

    GoRoute(
      path: '/',
      builder: (context, state) =>
      const HomePage(),
    ),

    // ============================================================
    // CATEGORIAS
    // ============================================================

    GoRoute(
      path: '/categorias',
      builder: (context, state) =>
      const CategoriasPage(),
    ),

    // ============================================================
    // RESULTADOS DE UMA CATEGORIA
    // ============================================================

    GoRoute(
      path: '/categoria/:tipo',
      builder: (context, state) {
        final categoria =
            state.pathParameters[
            'tipo'] ??
                '';

        return CategoriaResultadosPage(
          categoria: categoria,
        );
      },
    ),

    // ============================================================
    // ACERVO
    // ============================================================

    GoRoute(
      path: '/acervo',
      builder: (context, state) {
        final obraId =
        state.uri.queryParameters[
        'obra'];

        return AcervoResultadosPage(
          obraId: obraId,
        );
      },
    ),

    // ============================================================
    // PESQUISA DENTRO DO ACERVO
    // ============================================================

    GoRoute(
      path:
      '/acervo/pesquisa/:query',
      builder: (context, state) {
        final query =
            state.pathParameters[
            'query'] ??
                '';

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
        final query =
            state.pathParameters[
            'query'] ??
                '';

        return PesquisaResultadosPage(
          query: query,
        );
      },
    ),

    // ============================================================
    // MINHA CONTA
    // ============================================================

    GoRoute(
      path: '/minha-conta',
      builder: (context, state) =>
      const MinhaContaPage(),
    ),

    // ============================================================
    // CONFIGURAÇÕES
    // ============================================================

    GoRoute(
      path: '/configuracoes',
      builder: (context, state) =>
      const ConfiguracoesPage(),
    ),

    // ============================================================
    // PUBLICAR OBRA
    // ============================================================

    GoRoute(
      path: '/publicar',
      builder: (context, state) =>
      const PublicarObraPage(),
    ),

    // ============================================================
    // HISTÓRICO
    // ============================================================

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
      path:
      '/admin-solicitacoes-remocao',
      builder: (context, state) =>
      const AdminSolicitacoesRemocaoPage(),
    ),

    // ============================================================
    // PÁGINAS INFORMATIVAS
    // ============================================================

    GoRoute(
      path: '/termos',
      builder: (context, state) =>
      const TermosPage(),
    ),

    GoRoute(
      path:
      '/politica-privacidade',
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

// ================================================================
// REFRESH DO GO_ROUTER COM O ESTADO DE AUTENTICAÇÃO
// ================================================================

class GoRouterRefreshStream
    extends ChangeNotifier {
  GoRouterRefreshStream(
      Stream<dynamic> stream,
      ) {
    _subscription = stream
        .asBroadcastStream()
        .listen(
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
