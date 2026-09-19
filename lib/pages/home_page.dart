import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/auth_service.dart';
import '../services/historico_obras_service.dart';

import '../widgets/avatar_utilizador.dart';
import '../widgets/barra_pesquisa.dart';
import '../widgets/detalhes_obra_dialog.dart';
import '../widgets/foot_widget.dart';
import '../widgets/historico_lista_item.dart';
import '../widgets/obra_lista_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ObrasRepository _obrasRepository = ObrasRepository.instancia;

  final AuthService _authService = AuthService.instancia;

  final HistoricoObrasService _historicoService =
      HistoricoObrasService.instancia;

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obrasRecentes = [];
  List<HistoricoObra> _consultasRecentes = [];

  bool _carregandoObras = true;
  bool _carregandoConsultas = false;

  bool _ehAdmin = false;
  bool _carregandoPerfil = true;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        _authService.eventosAuth.listen(
          _tratarAlteracaoAutenticacao,
        );

    _carregarObrasRecentes();
    _carregarConsultasRecentes();
    _verificarAdministrador();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarConsultasRecentes();
        _verificarAdministrador();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _pesquisaController.dispose();
    super.dispose();
  }

  // ============================================================
  // AUTENTICAÇÃO
  // ============================================================

  void _tratarAlteracaoAutenticacao(
      AuthState estado,
      ) {
    if (!mounted) return;

    final bool autenticado =
        estado.session != null;

    setState(() {
      if (!autenticado) {
        _ehAdmin = false;
        _carregandoPerfil = false;
        _consultasRecentes = [];
        _carregandoConsultas = false;
      } else {
        _carregandoPerfil = true;
      }
    });

    if (autenticado) {
      _verificarAdministrador();
      _carregarConsultasRecentes();
    }
  }

  // ============================================================
  // CARREGAMENTO
  // ============================================================

  Future<void> _carregarObrasRecentes() async {
    if (mounted) {
      setState(() {
        _carregandoObras = true;
      });
    }

    try {
      final obras =
      await _obrasRepository.carregarObras(
        pagina: 1,
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _obrasRecentes = obras;
        _carregandoObras = false;
      });
    } catch (e) {
      debugPrint(
        'HOME: erro ao carregar obras recentes: $e',
      );

      if (!mounted) return;

      setState(() {
        _obrasRecentes = [];
        _carregandoObras = false;
      });
    }
  }

  Future<void> _carregarConsultasRecentes() async {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      if (!mounted) return;

      setState(() {
        _consultasRecentes = [];
        _carregandoConsultas = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _carregandoConsultas = true;
      });
    }

    try {
      final consultas =
      await _historicoService.obterConsultasRecentes(
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _consultasRecentes = consultas;
        _carregandoConsultas = false;
      });
    } catch (e) {
      debugPrint(
        'HOME: erro ao carregar consultas recentes: $e',
      );

      if (!mounted) return;

      setState(() {
        _consultasRecentes = [];
        _carregandoConsultas = false;
      });
    }
  }

  Future<void> _verificarAdministrador() async {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
        _carregandoPerfil = false;
      });

      return;
    }

    try {
      final ehAdmin =
      await _authService.ehAdmin();

      if (!mounted) return;

      setState(() {
        _ehAdmin = ehAdmin;
        _carregandoPerfil = false;
      });
    } catch (e) {
      debugPrint(
        'HOME: erro ao verificar administrador: $e',
      );

      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
        _carregandoPerfil = false;
      });
    }
  }

  // ============================================================
  // PESQUISA
  // ============================================================

  void _executarPesquisa() {
    final pesquisa =
    _pesquisaController.text.trim();

    if (pesquisa.isEmpty) return;

    context.go(
      '/acervo/pesquisa/'
          '${Uri.encodeComponent(pesquisa)}',
    );
  }

  void _limparPesquisa() {
    _pesquisaController.clear();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // ABRIR OBRA
  // ============================================================

  Future<void> _abrirObra(Obra obra) async {
    if (!mounted) return;

    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario != null) {
      try {
        await _historicoService.registrarConsulta(
          obraId: obra.id,
        );

        debugPrint(
          'HOME: consulta registrada ao abrir detalhes '
              'da obra ${obra.id}',
        );
      } catch (e) {
        debugPrint(
          'HOME: erro ao registrar consulta: $e',
        );
      }
    }

    if (!mounted) return;

    await mostrarDetalhesObraDialog(
      context,
      obra: obra,
      mostrarAbrir: true,
      onAbrir: () => _abrirDocumento(obra),
    );

    if (!mounted) return;

    if (usuario != null) {
      await _carregarConsultasRecentes();
    }
  }

  Future<void> _abrirDocumento(Obra obra) async {
    final url = obra.urlDocumento.trim();

    if (url.isEmpty) {
      _mostrarMensagem(
        'Esta obra não possui um documento disponível.',
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      _mostrarMensagem(
        'O endereço do documento é inválido.',
      );
      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );

      debugPrint(
        'HOME: documento aberto: $abriu',
      );

      if (!abriu) {
        _mostrarMensagem(
          'Não foi possível abrir o documento.',
        );
      }
    } catch (e) {
      debugPrint(
        'HOME: erro ao abrir documento: $e',
      );

      _mostrarMensagem(
        'Ocorreu um erro ao abrir o documento.',
      );
    }
  }

  Future<void> _abrirConsultaRecente(
      HistoricoObra consulta,
      ) async {
    final url =
    (consulta.urlDocumento ?? '').trim();

    if (url.isEmpty) {
      _mostrarMensagem(
        'Esta obra não possui um documento disponível.',
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      _mostrarMensagem(
        'O endereço do documento é inválido.',
      );
      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );

      if (!abriu) {
        _mostrarMensagem(
          'Não foi possível abrir o documento.',
        );
        return;
      }

      try {
        await _historicoService.registrarConsulta(
          obraId: consulta.obraId,
        );
      } catch (e) {
        debugPrint(
          'HOME: erro ao atualizar histórico: $e',
        );
      }

      if (mounted) {
        await _carregarConsultasRecentes();
      }
    } catch (e) {
      debugPrint(
        'HOME: erro ao abrir consulta recente: $e',
      );

      _mostrarMensagem(
        'Ocorreu um erro ao abrir o documento.',
      );
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF444444),
        backgroundColor: Colors.white,
        onRefresh: () async {
          await Future.wait([
            _carregarObrasRecentes(),
            _carregarConsultasRecentes(),
            _verificarAdministrador(),
          ]);
        },
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHero(),
              _buildCategorias(),
              _buildObrasRecentes(),
              _buildConsultasRecentes(),
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    final bool estaAutenticado =
        usuario != null;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 24,

      title: const Text(
        'Obra Livre',
        style: TextStyle(
          color: Color(0xFF222222),
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            context.go('/plataforma');
          },
          child: const Text(
            'Plataforma',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        TextButton(
          onPressed: () {
            context.go('/acervo');
          },
          child: const Text(
            'Acervo',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        if (estaAutenticado) ...[
          TextButton(
            onPressed: () {
              context.go('/publicar');
            },
            child: const Text(
              'Publicar',
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Padding(
            padding: const EdgeInsets.only(
              right: 18,
            ),
            child: PopupMenuButton<String>(
              tooltip: 'Conta',
              offset: const Offset(0, 48),

              onSelected: (value) async {
                switch (value) {
                  case 'conta':
                    if (mounted) {
                      context.go('/minha-conta');
                    }
                    break;

                  case 'configuracoes':
                    if (mounted) {
                      context.go('/configuracoes');
                    }
                    break;

                  case 'sair':
                    try {
                      await _authService.sair();

                      if (!mounted) return;

                      context.go('/login');
                    } catch (e) {
                      debugPrint(
                        'HOME: erro ao sair: $e',
                      );

                      if (!mounted) return;

                      _mostrarMensagem(
                        'Não foi possível terminar a sessão.',
                      );
                    }
                    break;
                }
              },

              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'conta',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Minha conta',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuItem<String>(
                  value: 'configuracoes',
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Configurações',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                const PopupMenuItem<String>(
                  value: 'sair',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Sair',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              child: const AvatarUtilizador(
                radius: 20,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(width: 4),

          TextButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text(
              'Entrar',
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              right: 18,
            ),
            child: TextButton(
              onPressed: () {
                context.go('/cadastro');
              },
              child: const Text(
                'Criar conta',
                style: TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        55,
        24,
        20,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          child: Column(
            children: [
              const Text(
                'Encontre conhecimento. '
                    'Encontre obras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Pesquise e consulte trabalhos '
                    'académicos, científicos e literários.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              BarraPesquisa(
                controller: _pesquisaController,
                hintText:
                'Pesquisar obras académicas',
                onPesquisar: _executarPesquisa,
                onLimpar: _limparPesquisa,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORIAS
  // ============================================================

  Widget _buildCategorias() {
    const categorias = [
      (
      nome: 'Tese Doutoramento',
      icone: Icons.school_outlined,
      ),
      (
      nome: 'Dissertação de Mestrado',
      icone: Icons.menu_book_outlined,
      ),
      (
      nome: 'Monografia',
      icone: Icons.description_outlined,
      ),
      (
      nome: 'Artigos Científicos',
      icone: Icons.article_outlined,
      ),
      (
      nome: 'Literatura',
      icone: Icons.auto_stories_outlined,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 30,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largura =
                  constraints.maxWidth;

              final colunas = largura >= 900
                  ? 5
                  : largura >= 650
                  ? 3
                  : 2;

              const espacamento = 24.0;

              final itemLargura =
                  (largura -
                      ((colunas - 1) *
                          espacamento)) /
                      colunas;

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: espacamento,
                runSpacing: 20,
                children: categorias
                    .map(
                      (categoria) => SizedBox(
                    width: itemLargura,
                    child: _buildCategoriaItem(
                      categoria.nome,
                      categoria.icone,
                    ),
                  ),
                )
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaItem(
      String nome,
      IconData icone,
      ) {
    return InkWell(
      onTap: () {
        context.go(
          '/categoria/'
              '${Uri.encodeComponent(nome)}',
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 6,
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 23,
              color: const Color(0xFF444444),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                nome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PUBLICAÇÕES RECENTES
  // ============================================================

  Widget _buildObrasRecentes() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 44,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Publicações recentes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Confira as obras publicadas '
                    'recentemente.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              if (_carregandoObras)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child:
                    CircularProgressIndicator(),
                  ),
                )
              else if (_obrasRecentes.isEmpty)
                _buildEstadoVazio(
                  'Ainda não existem '
                      'publicações disponíveis.',
                )
              else
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: _obrasRecentes
                      .map(
                        (obra) => ObraListaItem(
                      obra: obra,
                      onTap: () =>
                          _abrirObra(obra),
                    ),
                  )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONSULTAS RECENTES
  // ============================================================

  Widget _buildConsultasRecentes() {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 44,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Obras consultadas '
                        'recentemente',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Aceda rapidamente às obras '
                        'que consultou.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF777777),
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_carregandoConsultas)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child:
                    CircularProgressIndicator(),
                  ),
                )
              else if (_consultasRecentes.isEmpty)
                _buildEstadoVazio(
                  'Ainda não consultou nenhuma obra.',
                )
              else
                Column(
                  children: List.generate(
                    _consultasRecentes.length,
                        (index) {
                      final consulta =
                      _consultasRecentes[index];

                      return Column(
                        children: [
                          HistoricoListaItem(
                            obra: consulta,
                            onAbrir: () =>
                                _abrirConsultaRecente(
                                  consulta,
                                ),
                            onRemover: () {
                              // Mantida a lógica atual.
                            },
                          ),

                          if (index <
                              _consultasRecentes.length -
                                  1)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE5E5E5),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEstadoVazio(
      String mensagem,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Center(
        child: Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF777777),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

