import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import '../services/auth_service.dart';

// Páginas
import '../pages/login_page.dart';
import '../pages/cadastro_page.dart';
import '../pages/auth_callback_page.dart';
import '../pages/home_page.dart';
import '../pages/plataforma_page.dart';
import '../pages/categorias_page.dart';
import '../pages/categoria_resultados_page.dart';
import '../pages/acervo_resultados_page.dart';
import '../pages/acervo_pesquisa_resultados_page.dart';
import '../pages/pesquisa_resultados_page.dart';
import '../pages/minha_conta_page.dart';
import '../pages/configuracoes_page.dart';
import '../pages/publicar_obra_page.dart';
import '../pages/historico_obras_page.dart';
import '../pages/admin_obras_page.dart';
import '../pages/admin_solicitacoes_remocao_page.dart';
import '../pages/termos_page.dart';
import '../pages/politica_privacidade_page.dart';
import '../pages/cookies_page.dart';
import '../pages/contacto_page.dart';
import '../pages/ajuda_page.dart';

class AppRouter {
  static final AuthService _authService = AuthService.instancia;

  static const String _tituloBase = 'Obra Livre — Obras Académicas';

  static const String _descricaoBase =
      'Plataforma de consulta e publicação de obras académicas, '
      'teses, monografias e artigos científicos.';

  // ============================================================
  // SEO
  // ============================================================

  static void _definirDescricaoSeo(String descricao) {
    final meta = web.document.querySelector(
      'meta[name="description"]',
    );

    if (meta != null) {
      meta.setAttribute('content', descricao);
    } else {
      final novoMeta = web.document.createElement('meta');

      novoMeta.setAttribute('name', 'description');
      novoMeta.setAttribute('content', descricao);

      web.document.head?.appendChild(novoMeta);
    }
  }

  static Widget _paginaComSeo({
    required String titulo,
    required Widget child,
    String? descricao,
  }) {
    final descricaoFinal = descricao ?? _descricaoBase;

    _definirDescricaoSeo(descricaoFinal);

    return Title(
      title: titulo,
      color: Colors.black,
      child: child,
    );
  }

  // ============================================================
  // ROTAS PÚBLICAS
  // ============================================================

  static bool _ehRotaPublica(String caminho) {
    if (caminho == '/') {
      return true;
    }

    if (caminho == '/plataforma') {
      return true;
    }

    if (caminho == '/login') {
      return true;
    }

    if (caminho == '/cadastro') {
      return true;
    }

    if (caminho == '/auth/callback') {
      return true;
    }

    if (caminho == '/categorias') {
      return true;
    }

    if (caminho == '/acervo') {
      return true;
    }

    if (caminho == '/termos') {
      return true;
    }

    if (caminho == '/politica-privacidade') {
      return true;
    }

    if (caminho == '/cookies') {
      return true;
    }

    if (caminho == '/contacto') {
      return true;
    }

    if (caminho == '/ajuda') {
      return true;
    }

    if (caminho.startsWith('/categoria/')) {
      return true;
    }

    if (caminho.startsWith('/acervo/pesquisa/')) {
      return true;
    }

    if (caminho.startsWith('/search/')) {
      return true;
    }

    return false;
  }

  // ============================================================
  // ROUTER
  // ============================================================

  static final GoRouter router = GoRouter(
    initialLocation: '/',

    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),

    redirect: (context, state) {
      final bool estaAutenticado = _authService.estaAutenticado;

      final String caminho = state.uri.path;

      // ========================================================
      // DIAGNÓSTICO DAS ROTAS
      // ========================================================

      debugPrint('======================================');
      debugPrint('ROTA ATUAL: ${state.uri}');
      debugPrint('CAMINHO: $caminho');
      debugPrint('AUTENTICADO: $estaAutenticado');
      debugPrint('======================================');

      // ========================================================
      // RECUPERAR ROTA ENVIADA PELO 404 DO GITHUB PAGES
      // ========================================================

      final String? redirectOriginal =
      state.uri.queryParameters['redirect'];

      if (redirectOriginal != null &&
          redirectOriginal.isNotEmpty) {
        try {
          final String redirectDecodificado =
          Uri.decodeComponent(redirectOriginal);

          final Uri uriOriginal =
          Uri.parse(redirectDecodificado);

          String rota = uriOriginal.path;

          // Remove o prefixo do GitHub Pages.
          if (rota == '/teste') {
            rota = '/';
          } else if (rota.startsWith('/teste/')) {
            rota = rota.substring('/teste'.length);
          }

          if (!rota.startsWith('/')) {
            rota = '/$rota';
          }

          // Remove barra final, excepto na raiz.
          if (rota.length > 1 && rota.endsWith('/')) {
            rota = rota.substring(
              0,
              rota.length - 1,
            );
          }

          final String query =
          uriOriginal.hasQuery
              ? '?${uriOriginal.query}'
              : '';

          if (rota == '/') {
            return null;
          }

          final String rotaFinal = '$rota$query';

          debugPrint(
            'ROTA RECUPERADA DO 404: $rotaFinal',
          );

          return rotaFinal;
        } catch (e) {
          debugPrint(
            'ERRO AO RECUPERAR ROTA DO 404: $e',
          );
        }
      }

      // ========================================================
      // UTILIZADOR NÃO AUTENTICADO
      // ========================================================

      if (!estaAutenticado &&
          !_ehRotaPublica(caminho)) {
        debugPrint(
          'ROTA PROTEGIDA SEM LOGIN -> /login',
        );

        return '/login';
      }

      // ========================================================
      // UTILIZADOR AUTENTICADO
      // ========================================================

      if (estaAutenticado &&
          (caminho == '/login' ||
              caminho == '/cadastro')) {
        debugPrint(
          'UTILIZADOR AUTENTICADO -> /',
        );

        return '/';
      }

      // ========================================================
      // NÃO REDIRECIONAR
      // ========================================================

      debugPrint(
        'SEM REDIRECIONAMENTO: $caminho',
      );

      return null;
    },

    routes: [
      // ========================================================
      // LOGIN
      // ========================================================

      GoRoute(
        path: '/login',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Entrar — $_tituloBase',
            descricao:
            'Entre na Obra Livre para publicar e gerir as suas obras.',
            child: const LoginPage(),
          );
        },
      ),

      // ========================================================
      // CADASTRO
      // ========================================================

      GoRoute(
        path: '/cadastro',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Criar conta — $_tituloBase',
            descricao:
            'Crie uma conta na Obra Livre para publicar e gerir as suas obras.',
            child: const CadastroPage(),
          );
        },
      ),

      // ========================================================
      // CALLBACK SUPABASE
      // ========================================================

      GoRoute(
        path: '/auth/callback',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Autenticação — $_tituloBase',
            child: const AuthCallbackPage(),
          );
        },
      ),

      // ========================================================
      // HOME
      // ========================================================

      GoRoute(
        path: '/',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: _tituloBase,
            descricao: _descricaoBase,
            child: const HomePage(),
          );
        },
      ),

      // ========================================================
      // PLATAFORMA
      // ========================================================

      GoRoute(
        path: '/plataforma',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Plataforma — $_tituloBase',
            descricao:
            'Conheça a plataforma Obra Livre e os seus recursos.',
            child: const PlataformaPage(),
          );
        },
      ),

      // ========================================================
      // CATEGORIAS
      // ========================================================

      GoRoute(
        path: '/categorias',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Categorias — $_tituloBase',
            descricao:
            'Explore as categorias de obras disponíveis na Obra Livre.',
            child: const CategoriasPage(),
          );
        },
      ),

      // ========================================================
      // CATEGORIA ESPECÍFICA
      // ========================================================

      GoRoute(
        path: '/categoria/:tipo',
        builder: (context, state) {
          final String tipo =
              state.pathParameters['tipo'] ?? '';

          return _paginaComSeo(
            titulo: '$tipo — $_tituloBase',
            descricao:
            'Consulte obras da categoria $tipo na Obra Livre.',
            child: CategoriaResultadosPage(
              categoria: tipo,
            ),
          );
        },
      ),

      // ========================================================
      // ACERVO
      // ========================================================

      GoRoute(
        path: '/acervo',
        builder: (context, state) {
          final String? obraId =
          state.uri.queryParameters['obra'];

          return _paginaComSeo(
            titulo: 'Acervo — $_tituloBase',
            descricao:
            'Consulte obras académicas, científicas e literárias no acervo da Obra Livre.',
            child: AcervoResultadosPage(
              obraId: obraId,
            ),
          );
        },
      ),

      // ========================================================
      // PESQUISA DO ACERVO
      // ========================================================

      GoRoute(
        path: '/acervo/pesquisa/:query',
        builder: (context, state) {
          final String query =
              state.pathParameters['query'] ?? '';

          return _paginaComSeo(
            titulo: 'Pesquisa: $query — $_tituloBase',
            descricao:
            'Resultados da pesquisa por $query na Obra Livre.',
            child: AcervoPesquisaResultadosPage(
              query: query,
            ),
          );
        },
      ),

      // ========================================================
      // PESQUISA GERAL
      // ========================================================

      GoRoute(
        path: '/search/:query',
        builder: (context, state) {
          final String query =
              state.pathParameters['query'] ?? '';

          return _paginaComSeo(
            titulo: 'Pesquisa: $query — $_tituloBase',
            descricao:
            'Resultados da pesquisa por $query na Obra Livre.',
            child: PesquisaResultadosPage(
              query: query,
            ),
          );
        },
      ),

      // ========================================================
      // MINHA CONTA
      // ========================================================

      GoRoute(
        path: '/minha-conta',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Minha conta — $_tituloBase',
            child: const MinhaContaPage(),
          );
        },
      ),

      // ========================================================
      // CONFIGURAÇÕES
      // ========================================================

      GoRoute(
        path: '/configuracoes',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Configurações — $_tituloBase',
            child: const ConfiguracoesPage(),
          );
        },
      ),

      // ========================================================
      // PUBLICAR
      // ========================================================

      GoRoute(
        path: '/publicar',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Publicar obra — $_tituloBase',
            child: const PublicarObraPage(),
          );
        },
      ),

      // ========================================================
      // HISTÓRICO
      // ========================================================

      GoRoute(
        path: '/historico-obras',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Histórico de obras — $_tituloBase',
            child: const HistoricoObrasPage(),
          );
        },
      ),

      // ========================================================
      // ADMIN — OBRAS
      // ========================================================

      GoRoute(
        path: '/admin-obras',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Administração de obras — $_tituloBase',
            child: const AdminObrasPage(),
          );
        },
      ),

      // ========================================================
      // ADMIN — SOLICITAÇÕES DE REMOÇÃO
      // ========================================================

      GoRoute(
        path: '/admin-solicitacoes-remocao',
        builder: (context, state) {
          return _paginaComSeo(
            titulo:
            'Solicitações de remoção — $_tituloBase',
            child:
            const AdminSolicitacoesRemocaoPage(),
          );
        },
      ),

      // ========================================================
      // TERMOS
      // ========================================================

      GoRoute(
        path: '/termos',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Termos de utilização — $_tituloBase',
            child: const TermosPage(),
          );
        },
      ),

      // ========================================================
      // POLÍTICA DE PRIVACIDADE
      // ========================================================

      GoRoute(
        path: '/politica-privacidade',
        builder: (context, state) {
          return _paginaComSeo(
            titulo:
            'Política de privacidade — $_tituloBase',
            child:
            const PoliticaPrivacidadePage(),
          );
        },
      ),

      // ========================================================
      // COOKIES
      // ========================================================

      GoRoute(
        path: '/cookies',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Cookies — $_tituloBase',
            child: const CookiesPage(),
          );
        },
      ),

      // ========================================================
      // CONTACTO
      // ========================================================

      GoRoute(
        path: '/contacto',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Contacto — $_tituloBase',
            child: const ContactoPage(),
          );
        },
      ),

      // ========================================================
      // AJUDA
      // ========================================================

      GoRoute(
        path: '/ajuda',
        builder: (context, state) {
          return _paginaComSeo(
            titulo: 'Ajuda — $_tituloBase',
            child: const AjudaPage(),
          );
        },
      ),
    ],
  );
}

// ============================================================
// REFRESH DO GO ROUTER COM SUPABASE AUTH
// ============================================================

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
          (_) {
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
