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
import '../widgets/foot_widget.dart';
import '../widgets/historico_lista_item.dart';
import '../widgets/obra_lista_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  final AuthService _authService =
      AuthService.instancia;

  final HistoricoObrasService
  _historicoService =
      HistoricoObrasService.instancia;

  final TextEditingController
  _pesquisaController =
  TextEditingController();

  List<Obra> _obrasRecentes = [];
  List<HistoricoObra>
  _consultasRecentes = [];

  bool _carregandoObras = true;
  bool _carregandoConsultas = false;
  bool _ehAdmin = false;
  bool _carregandoPerfil = true;

  StreamSubscription<AuthState>?
  _authSubscription;

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
  void dispose() {
    _authSubscription?.cancel();
    _pesquisaController.dispose();
    super.dispose();
  }

  void _tratarAlteracaoAutenticacao(
      AuthState estado,
      ) {
    if (!mounted) return;

    final autenticado = estado.session != null;

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

  Future<void> _carregarConsultasRecentes()
  async {
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

  Future<void> _atualizarTudo() async {
    await Future.wait([
      _carregarObrasRecentes(),
      _carregarConsultasRecentes(),
      _verificarAdministrador(),
    ]);
  }

  void _executarPesquisa() {
    final pesquisa =
    _pesquisaController.text.trim();

    if (pesquisa.isEmpty) return;

    context.go(
      '/acervo/pesquisa/${Uri.encodeComponent(pesquisa)}',
    );
  }

  void _limparPesquisa() {
    _pesquisaController.clear();

    if (mounted) {
      setState(() {});
    }
  }

  void _abrirConta() {
    if (_ehAdmin) {
      context.go('/admin-obras');
    } else {
      context.go('/minha-conta');
    }
  }

  void _abrirObra(Obra obra) {
    if (!mounted) return;

    context.go('/obra/${obra.id}');
  }

  Future<void> _abrirDocumento(
      Obra obra,
      ) async {
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
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFCFCFC),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF333333),
        backgroundColor: Colors.white,
        onRefresh: _atualizarTudo,
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

  PreferredSizeWidget _buildAppBar() {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    final estaAutenticado = usuario != null;

    return AppBar(
      backgroundColor:
      const Color(0xFFEAF4FF),
      elevation: 0,
      surfaceTintColor:
      const Color(0xFFEAF4FF),
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      titleSpacing: 28,
      bottom: const PreferredSize(
        preferredSize:
        Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD5E5F5),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: const Text(
              'Obra Livre',
              style: TextStyle(
                color: Color(0xFF1F1F1F),
                fontSize: 21,
                fontWeight:
                FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),

          const SizedBox(width: 28),

          _buildNavButton(
            label: 'Plataforma',
            onPressed: () {
              context.go('/plataforma');
            },
          ),

          if (!estaAutenticado) ...[
            const SizedBox(width: 2),

            _buildNavButton(
              label: 'Acervo',
              onPressed: () {
                context.go('/acervo');
              },
            ),
          ],

          if (estaAutenticado &&
              !_ehAdmin) ...[
            const SizedBox(width: 2),

            _buildNavButton(
              label: 'Acervo',
              onPressed: () {
                context.go('/acervo');
              },
            ),

            const SizedBox(width: 2),

            _buildNavButton(
              label: 'Publicar',
              onPressed: () {
                context.go('/publicar');
              },
            ),
          ],
        ],
      ),

      actions: [
        if (estaAutenticado) ...[
          const SizedBox(width: 12),

          Padding(
            padding:
            const EdgeInsets.only(
              right: 24,
            ),
            child:
            PopupMenuButton<String>(
              tooltip: 'Conta',
              offset:
              const Offset(0, 50),
              elevation: 4,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(10),
              ),
              onSelected:
                  (value) async {
                switch (value) {
                  case 'conta':
                    _abrirConta();
                    break;

                  case 'configuracoes':
                    context.go(
                      '/minha-conta',
                    );
                    break;

                  case 'sair':
                    try {
                      await _authService
                          .sair();

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
              itemBuilder:
                  (context) => [
                PopupMenuItem<String>(
                  value: 'conta',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 19,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        _ehAdmin
                            ? 'Administração'
                            : 'Minha conta',
                        style:
                        const TextStyle(
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
                        style:
                        TextStyle(
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
                        style:
                        TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child:
              const AvatarUtilizador(
                radius: 20,
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            height: 38,
            child: TextButton(
              onPressed: () {
                context.go('/login');
              },
              style:
              TextButton.styleFrom(
                backgroundColor:
                const Color(0xFF222222),
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Padding(
            padding:
            const EdgeInsets.only(
              right: 24,
            ),
            child: SizedBox(
              height: 38,
              child: TextButton(
                onPressed: () {
                  context.go('/cadastro');
                },
                style:
                TextButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFF7F7F7),
                  foregroundColor:
                  const Color(0xFF222222),
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  side:
                  const BorderSide(
                    color:
                    Color(0xFFD8D8D8),
                    width: 1,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Criar conta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor:
        const Color(0xFF444444),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(7),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight:
          FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // HERO COM IMAGEM DE FUNDO
  // ============================================================

  Widget _buildHero() {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/livros_home.png',
            fit: BoxFit.cover,
          ),

          Container(
            color:
            Colors.black.withOpacity(0.42),
          ),

          Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 900,
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Publique e encontre conhecimento.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight:
                        FontWeight.w700,
                        color: Colors.white,
                        height: 1.18,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const SizedBox(
                      width: 620,
                      child: Text(
                        'Pesquise e consulte obras académicas, científicas e literárias.',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white,
                          height: 1.55,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    ConstrainedBox(
                      constraints:
                      const BoxConstraints(
                        maxWidth: 760,
                      ),
                      child: BarraPesquisa(
                        controller:
                        _pesquisaController,
                        hintText:
                        'Pesquisar obras académicas',
                        onPesquisar:
                        _executarPesquisa,
                        onLimpar:
                        _limparPesquisa,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorias() {
    const categorias = [
      'Tese de Doutoramento',
      'Dissertação de Mestrado',
      'Monografia',
      'Artigos Científicos',
      'Comunicações Científicas',
      'Posters',
      'Resumos',
      'Relatórios Académicos',
      'Trabalhos Académicos',
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
      const EdgeInsets.fromLTRB(
        24,
        34,
        24,
        48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore as obras por tipo de publicação.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              LayoutBuilder(
                builder:
                    (context, constraints) {
                  final largura =
                      constraints.maxWidth;

                  final colunas =
                  largura >= 1000
                      ? 5
                      : largura >= 650
                      ? 3
                      : 2;

                  const espacamentoHorizontal =
                  10.0;

                  const espacamentoVertical =
                  10.0;

                  final itemLargura =
                      (largura -
                          ((colunas - 1) *
                              espacamentoHorizontal)) /
                          colunas;

                  return Wrap(
                    spacing:
                    espacamentoHorizontal,
                    runSpacing:
                    espacamentoVertical,
                    children:
                    categorias
                        .map(
                          (categoria) =>
                          SizedBox(
                            width:
                            itemLargura,
                            child:
                            _buildCategoriaItem(
                              categoria,
                            ),
                          ),
                    )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaItem(
      String nome,
      ) {
    return InkWell(
      onTap: () {
        context.go(
          '/categoria/${Uri.encodeComponent(nome)}',
        );
      },
      borderRadius:
      BorderRadius.circular(8),
      hoverColor:
      Colors.transparent,
      splashColor:
      Colors.transparent,
      highlightColor:
      Colors.transparent,
      focusColor:
      Colors.transparent,
      child: Container(
        constraints:
        const BoxConstraints(
          minHeight: 48,
        ),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration:
        BoxDecoration(
          color: Colors.transparent,
          borderRadius:
          BorderRadius.circular(8),
          border: Border.all(
            color:
            const Color(0xFFE1E4E7),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          nome,
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight:
            FontWeight.w500,
            color:
            Color(0xFF333333),
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildObrasRecentes() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 38,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
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
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF222222),
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Confira as obras publicadas recentemente.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 5),

              if (_carregandoObras)
                const Center(
                  child: Padding(
                    padding:
                    EdgeInsets.all(30),
                    child:
                    CircularProgressIndicator(),
                  ),
                )
              else if (_obrasRecentes.isEmpty)
                _buildEstadoVazio(
                  'Ainda não existem publicações disponíveis.',
                )
              else
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children:
                  _obrasRecentes
                      .map(
                        (obra) =>
                        ObraListaItem(
                          obra: obra,
                          onTap: () =>
                              _abrirObra(
                                obra,
                              ),
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

  Widget _buildConsultasRecentes() {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 38,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 1100,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Obras consultadas recentemente',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF222222),
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Aceda rapidamente às obras que consultou.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                  Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              if (_carregandoConsultas)
                const Center(
                  child: Padding(
                    padding:
                    EdgeInsets.all(30),
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
                  children:
                  List.generate(
                    _consultasRecentes.length,
                        (index) {
                      final consulta =
                      _consultasRecentes[index];

                      return HistoricoListaItem(
                        obra: consulta,
                        onAbrir: () =>
                            _abrirConsultaRecente(
                              consulta,
                            ),
                        onRemover: () {},
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

  Widget _buildEstadoVazio(
      String mensagem,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color:
          const Color(0xFFE5E5E5),
        ),
      ),
      child: Center(
        child: Text(
          mensagem,
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color:
            Color(0xFF777777),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
