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
import '../pages/obra_detalhes_page.dart';
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

const String _tituloBase = 'Obra Livre — Obras Académicas';

const String _descricaoSeo =
    'Plataforma de consulta e publicação de obras académicas, '
    'teses, monografias e artigos científicos.';

void _definirDescricaoSeo(String descricao) {
  final web.Element? elemento =
  web.document.querySelector('meta[name="description"]');

  if (elemento != null) {
    elemento.setAttribute('content', descricao);
    return;
  }

  final web.HTMLMetaElement novaMeta =
  web.document.createElement('meta') as web.HTMLMetaElement;

  novaMeta.name = 'description';
  novaMeta.content = descricao;

  web.document.head?.appendChild(novaMeta);
}

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
      caminho.startsWith('/obra/') ||
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

  redirect: (BuildContext context, GoRouterState state) {
    final bool estaAutenticado = _authService.estaAutenticado;
    final String caminho = state.uri.path;
    final bool rotaPublica = _ehRotaPublica(caminho);

    if (!estaAutenticado && !rotaPublica) {
      return '/login';
    }

    if (estaAutenticado &&
        (caminho == '/login' || caminho == '/cadastro')) {
      return '/';
    }

    return null;
  },

  routes: <RouteBase>[
    // ========================================================
    // LOGIN
    // ========================================================

    GoRoute(
      path: '/login',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Entrar — $_tituloBase',
        child: const LoginPage(),
      ),
    ),

    // ========================================================
    // CADASTRO
    // ========================================================

    GoRoute(
      path: '/cadastro',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Criar conta — $_tituloBase',
        child: const CadastroPage(),
      ),
    ),

    // ========================================================
    // CALLBACK SUPABASE
    // ========================================================

    GoRoute(
      path: '/auth/callback',
      builder: (context, state) => _paginaComTitulo(
        titulo: _tituloBase,
        child: const AuthCallbackPage(),
      ),
    ),

    // ========================================================
    // HOME
    // ========================================================

    GoRoute(
      path: '/',
      builder: (context, state) => _paginaComSeo(
        titulo: _tituloBase,
        descricao: _descricaoSeo,
        child: const HomePage(),
      ),
    ),

    // ========================================================
    // PLATAFORMA
    // ========================================================

    GoRoute(
      path: '/plataforma',
      builder: (context, state) => _paginaComSeo(
        titulo: 'Plataforma — $_tituloBase',
        descricao:
        'Conheça a plataforma Obra Livre para consulta e publicação '
            'de obras académicas.',
        child: const PlataformaPage(),
      ),
    ),

    // ========================================================
    // CATEGORIAS
    // ========================================================

    GoRoute(
      path: '/categorias',
      builder: (context, state) => _paginaComSeo(
        titulo: 'Categorias — $_tituloBase',
        descricao: 'Explore categorias de obras académicas.',
        child: const CategoriasPage(),
      ),
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
          titulo: '$tipo — $_tituloBase',
          descricao: 'Categoria de obras académicas.',
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
          'Consulte obras académicas disponíveis no acervo.',
          child: AcervoResultadosPage(
            obraId: obraId,
          ),
        );
      },
    ),

    // ========================================================
    // DETALHES DA OBRA
    // ========================================================

    GoRoute(
      path: '/obra/:id',
      builder: (context, state) {
        final String id =
            state.pathParameters['id'] ?? '';

        return ObraDetalhesPage(
          id: id,
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
          descricao:
          'Pesquise obras académicas no acervo.',
          child: AcervoPesquisaResultadosPage(
            query: query,
          ),
        );
      },
    ),

    // ========================================================
    // PESQUISA
    // ========================================================

    GoRoute(
      path: '/search/:query',
      builder: (context, state) {
        final String query =
            state.pathParameters['query'] ?? '';

        return _paginaComSeo(
          titulo: 'Pesquisa — $_tituloBase',
          descricao:
          'Pesquise obras académicas na plataforma.',
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
      redirect: (context, state) async {
        if (!_authService.estaAutenticado) {
          return '/login';
        }

        final bool ehAdministrador =
        await _authService.ehAdmin();

        if (ehAdministrador) {
          return '/admin-obras';
        }

        return null;
      },
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Minha conta — $_tituloBase',
        child: const MinhaContaPage(),
      ),
    ),

    // ========================================================
    // CONFIGURAÇÕES
    // ========================================================

    GoRoute(
      path: '/configuracoes',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Configurações — $_tituloBase',
        child: const ConfiguracoesPage(),
      ),
    ),

    // ========================================================
    // PUBLICAR
    // ========================================================

    GoRoute(
      path: '/publicar',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Publicar obra — $_tituloBase',
        child: const PublicarObraPage(),
      ),
    ),

    // ========================================================
    // HISTÓRICO
    // ========================================================

    GoRoute(
      path: '/historico-obras',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Histórico de obras — $_tituloBase',
        child: const HistoricoObrasPage(),
      ),
    ),

    // ========================================================
    // ADMINISTRAÇÃO DE OBRAS
    // ========================================================

    GoRoute(
      path: '/admin-obras',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Administração de obras — $_tituloBase',
        child: const AdminObrasPage(),
      ),
    ),

    // ========================================================
    // ADMINISTRAÇÃO DE SOLICITAÇÕES
    // ========================================================

    GoRoute(
      path: '/admin-solicitacoes-remocao',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Solicitações de remoção — $_tituloBase',
        child: const AdminSolicitacoesRemocaoPage(),
      ),
    ),

    // ========================================================
    // TERMOS
    // ========================================================

    GoRoute(
      path: '/termos',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Termos de utilização — $_tituloBase',
        child: const TermosPage(),
      ),
    ),

    // ========================================================
    // POLÍTICA DE PRIVACIDADE
    // ========================================================

    GoRoute(
      path: '/politica-privacidade',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Política de privacidade — $_tituloBase',
        child: const PoliticaPrivacidadePage(),
      ),
    ),

    // ========================================================
    // COOKIES
    // ========================================================

    GoRoute(
      path: '/cookies',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Política de cookies — $_tituloBase',
        child: const CookiesPage(),
      ),
    ),

    // ========================================================
    // CONTACTO
    // ========================================================

    GoRoute(
      path: '/contacto',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Contacto — $_tituloBase',
        child: const ContactoPage(),
      ),
    ),

    // ========================================================
    // AJUDA
    // ========================================================

    GoRoute(
      path: '/ajuda',
      builder: (context, state) => _paginaComTitulo(
        titulo: 'Ajuda — $_tituloBase',
        child: const AjudaPage(),
      ),
    ),
  ],

  // ==========================================================
  // ERRO 404
  // ==========================================================

  errorBuilder: (context, state) => const Scaffold(
    body: Center(
      child: Text(
        'Página não encontrada',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
);

// ============================================================
// REFRESH DO GOROUTER
// ============================================================

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription =
        stream.asBroadcastStream().listen((_) {
          notifyListeners();
        });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
