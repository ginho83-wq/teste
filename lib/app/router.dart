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

// ============================================================
// SEO
// ============================================================

const String _tituloBase = 'Teste — Obras Académicas';

const String _descricaoSeo =
    'Plataforma de consulta e publicação de obras académicas, '
    'teses, monografias e artigos científicos.';

const String _descricaoHome =
    'Plataforma de consulta e publicação de obras académicas, '
    'teses, monografias e artigos científicos.';

const String _descricaoPlataforma =
    'Conheça a plataforma Teste para consulta e publicação '
    'de obras académicas, teses, monografias e artigos científicos.';

const String _descricaoCategorias =
    'Explore categorias de obras académicas, incluindo teses, '
    'monografias, artigos científicos e literatura.';

const String _descricaoAcervo =
    'Consulte teses, monografias, artigos científicos e outras '
    'obras académicas disponíveis no acervo.';

const String _descricaoTeseDoutoramento =
    'Consulte teses de doutoramento e outras obras académicas '
    'disponíveis no acervo.';

const String _descricaoTeseMestrado =
    'Consulte teses de mestrado e outras obras académicas '
    'disponíveis no acervo.';

const String _descricaoMonografia =
    'Consulte monografias académicas disponíveis no acervo.';

const String _descricaoArtigos =
    'Consulte artigos científicos e outras publicações '
    'académicas disponíveis no acervo.';

const String _descricaoLiteratura =
    'Explore obras de literatura disponíveis no acervo.';

const String _descricaoPesquisaAcervo =
    'Pesquise teses, monografias, artigos científicos e outras '
    'obras académicas no acervo.';

const String _descricaoPesquisaGeral =
    'Pesquise obras académicas, teses, monografias e artigos '
    'científicos na plataforma Teste.';

// ============================================================
// ATUALIZAÇÃO DA DESCRIÇÃO SEO
// ============================================================

void _definirDescricaoSeo(String descricao) {
  final web.Element? elemento =
  web.document.querySelector('meta[name="description"]');

  if (elemento != null) {
    elemento.setAttribute('content', descricao);
    return;
  }

  final web.HTMLMetaElement novaMeta =
  web.document.createElement('meta')
  as web.HTMLMetaElement;

  novaMeta.name = 'description';
  novaMeta.content = descricao;

  web.document.head?.appendChild(novaMeta);
}

// ============================================================
// TÍTULO + DESCRIÇÃO SEO
// ============================================================

Widget _paginaComSeo({
  required String titulo,
  required String descricao,
  required Widget child,
}) {
  _definirDescricaoSeo(descricao);

  return Title(
    title: titulo,
    color: Colors.white,
    child: child,
  );
}

// ============================================================
// COMPATIBILIDADE COM PÁGINAS SEM DESCRIÇÃO ESPECÍFICA
// ============================================================

Widget _paginaComTitulo({
  required String titulo,
  required Widget child,
}) {
  return _paginaComSeo(
    titulo: titulo,
    descricao: _descricaoSeo,
    child: child,
  );
}

// ============================================================
// TÍTULOS DAS CATEGORIAS
// ============================================================

String _tituloCategoria(String tipo) {
  final String categoria =
  tipo.replaceAll('-', ' ').trim();

  if (categoria.isEmpty) {
    return 'Categorias — $_tituloBase';
  }

  final String categoriaFormatada = categoria
      .split(' ')
      .map(
        (String palavra) => palavra.isEmpty
        ? palavra
        : '${palavra[0].toUpperCase()}'
        '${palavra.substring(1)}',
  )
      .join(' ');

  return '$categoriaFormatada — $_tituloBase';
}

// ============================================================
// DESCRIÇÃO SEO DAS CATEGORIAS
// ============================================================

String _descricaoCategoria(String tipo) {
  switch (tipo.toLowerCase()) {
    case 'tese-doutoramento':
      return _descricaoTeseDoutoramento;

    case 'tese-mestrado':
      return _descricaoTeseMestrado;

    case 'monografia':
      return _descricaoMonografia;

    case 'artigos-cientificos':
      return _descricaoArtigos;

    case 'literatura':
      return _descricaoLiteratura;

    default:
      return _descricaoCategorias;
  }
}

// ============================================================
// ROTAS PÚBLICAS
// ============================================================

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
      caminho.startsWith('/acervo/pesquisa/') ||
      caminho.startsWith('/search/');
}

// ============================================================
// ROUTER PRINCIPAL
// ============================================================

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

    // ========================================================
    // VISITANTE NÃO AUTENTICADO
    // ========================================================

    if (!estaAutenticado && !rotaPublica) {
      return '/login';
    }

    // ========================================================
    // UTILIZADOR AUTENTICADO
    // ========================================================

    if (estaAutenticado &&
        (caminho == '/login' ||
            caminho == '/cadastro')) {
      return '/';
    }

    return null;
  },

  routes: <RouteBase>[

    // ========================================================
    // AUTENTICAÇÃO
    // ========================================================

    GoRoute(
      path: '/login',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Entrar — $_tituloBase',
          child: const LoginPage(),
        );
      },
    ),

    GoRoute(
      path: '/cadastro',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Criar conta — $_tituloBase',
          child: const CadastroPage(),
        );
      },
    ),

    GoRoute(
      path: '/auth/callback',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: _tituloBase,
          child: const AuthCallbackPage(),
        );
      },
    ),

    // ========================================================
    // PÁGINA INICIAL
    // ========================================================

    GoRoute(
      path: '/',
      builder: (context, state) {
        return _paginaComSeo(
          titulo: _tituloBase,
          descricao: _descricaoHome,
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
          descricao: _descricaoPlataforma,
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
          descricao: _descricaoCategorias,
          child: const CategoriasPage(),
        );
      },
    ),

    // ========================================================
    // RESULTADOS POR CATEGORIA
    // ========================================================

    GoRoute(
      path: '/categoria/:tipo',
      builder: (context, state) {
        final String tipo =
            state.pathParameters['tipo'] ?? '';

        return _paginaComSeo(
          titulo: _tituloCategoria(tipo),
          descricao: _descricaoCategoria(tipo),
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
          descricao: _descricaoAcervo,
          child: AcervoResultadosPage(
            obraId: obraId,
          ),
        );
      },
    ),

    // ========================================================
    // PESQUISA NO ACERVO
    // ========================================================

    GoRoute(
      path: '/acervo/pesquisa/:query',
      builder: (context, state) {
        final String query =
            state.pathParameters['query'] ?? '';

        return _paginaComSeo(
          titulo: 'Pesquisa no Acervo — $_tituloBase',
          descricao: _descricaoPesquisaAcervo,
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
          titulo: 'Pesquisa — $_tituloBase',
          descricao: _descricaoPesquisaGeral,
          child: PesquisaResultadosPage(
            query: query,
          ),
        );
      },
    ),

    // ========================================================
    // ÁREA DO UTILIZADOR
    // ========================================================

    GoRoute(
      path: '/minha-conta',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Minha conta — $_tituloBase',
          child: const MinhaContaPage(),
        );
      },
    ),

    GoRoute(
      path: '/configuracoes',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Configurações — $_tituloBase',
          child: const ConfiguracoesPage(),
        );
      },
    ),

    GoRoute(
      path: '/publicar',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Publicar obra — $_tituloBase',
          child: const PublicarObraPage(),
        );
      },
    ),

    GoRoute(
      path: '/historico-obras',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Histórico de obras — $_tituloBase',
          child: const HistoricoObrasPage(),
        );
      },
    ),

    // ========================================================
    // ADMINISTRAÇÃO
    // ========================================================

    GoRoute(
      path: '/admin-obras',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Administração de obras — $_tituloBase',
          child: const AdminObrasPage(),
        );
      },
    ),

    GoRoute(
      path: '/admin-solicitacoes-remocao',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Solicitações de remoção — $_tituloBase',
          child: const AdminSolicitacoesRemocaoPage(),
        );
      },
    ),

    // ========================================================
    // PÁGINAS INFORMATIVAS / LEGAIS
    // ========================================================

    GoRoute(
      path: '/termos',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Termos de utilização — $_tituloBase',
          child: const TermosPage(),
        );
      },
    ),

    GoRoute(
      path: '/politica-privacidade',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Política de privacidade — $_tituloBase',
          child: const PoliticaPrivacidadePage(),
        );
      },
    ),

    GoRoute(
      path: '/cookies',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Política de cookies — $_tituloBase',
          child: const CookiesPage(),
        );
      },
    ),

    GoRoute(
      path: '/contacto',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Contacto — $_tituloBase',
          child: const ContactoPage(),
        );
      },
    ),

    GoRoute(
      path: '/ajuda',
      builder: (context, state) {
        return _paginaComTitulo(
          titulo: 'Ajuda — $_tituloBase',
          child: const AjudaPage(),
        );
      },
    ),
  ],
);

// ============================================================
// REFRESH DO GOROUTER
// ============================================================

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription =
        stream.asBroadcastStream().listen(
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
