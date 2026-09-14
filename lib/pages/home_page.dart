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
import '../widgets/detalhes_obra_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ObrasRepository _obrasRepository = ObrasRepository.instancia;
  final AuthService _authService = AuthService.instancia;
  final HistoricoObrasService _historicoService =
  HistoricoObrasService();

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obrasRecentes = [];
  List<HistoricoObra> _consultasRecentes = [];

  bool _carregandoObras = true;
  bool _carregandoConsultas = true;

  bool _ehAdmin = false;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();

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
      }
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
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
      final obras = await _obrasRepository.carregarObras(
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
    try {
      final ehAdmin = await _authService.ehAdmin();

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
    final pesquisa = _pesquisaController.text.trim();

    if (pesquisa.isEmpty) return;

    context.go(
      '/search/${Uri.encodeComponent(pesquisa)}',
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

    // Registra a consulta.
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

    if (!mounted) return;

    // ==========================================================
    // USA O MESMO DIÁLOGO DO ACERVO
    // ==========================================================
    await mostrarDetalhesObraDialog(
      context,
      obra: obra,
      mostrarAbrir: true,
      onAbrir: () => _abrirDocumento(obra),
    );

    if (!mounted) return;

    await _carregarConsultasRecentes();
  }

  Future<void> _abrirDocumento(Obra obra) async {
    final url = (obra.urlDocumento ?? '').trim();

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
    final url = (consulta.urlDocumento ?? '').trim();

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
              _buildFooter(),
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
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.go('/acervo');
          },
          child: const Text(
            'Acervo',
            style: TextStyle(
              color: Color(0xFF444444),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        if (!_carregandoPerfil && _ehAdmin)
          TextButton(
            onPressed: () {
              context.go('/admin-obras');
            },
            child: const Text(
              'Administração',
              style: TextStyle(
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        TextButton(
          onPressed: () {
            context.go('/publicar');
          },
          child: const Text(
            'Publicar',
            style: TextStyle(
              color: Color(0xFF444444),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Padding(
          padding:
          const EdgeInsets.only(right: 18),
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
                  await _authService.sair();

                  if (!mounted) return;

                  context.go('/login');
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
                    Text('Minha conta'),
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
                    Text('Configurações'),
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
                    Text('Sair'),
                  ],
                ),
              ),
            ],
            child: const AvatarUtilizador(
              radius: 20,
            ),
          ),
        ),
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
        55,
      ),
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              const Text(
                'Encontre conhecimento. Encontre obras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pesquise e consulte trabalhos académicos, '
                    'científicos e literários.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _buildBarraPesquisaHome(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarraPesquisaHome() {
    return Container(
      constraints:
      const BoxConstraints(maxWidth: 720),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFD5D5D5),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search,
            color: Color(0xFF777777),
            size: 22,
          ),
          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: _pesquisaController,
              textInputAction:
              TextInputAction.search,
              onSubmitted: (_) {
                _executarPesquisa();
              },
              onChanged: (_) {
                setState(() {});
              },
              decoration:
              const InputDecoration(
                hintText:
                'Pesquisar obras académicas',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),

          if (_pesquisaController.text
              .trim()
              .isNotEmpty)
            IconButton(
              tooltip: 'Limpar pesquisa',
              onPressed: _limparPesquisa,
              icon: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF777777),
              ),
            ),

          const SizedBox(width: 4),

          SizedBox(
            height: 42,
            child: Padding(
              padding:
              const EdgeInsets.only(right: 5),
              child: ElevatedButton(
                onPressed: _executarPesquisa,
                style:
                ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor:
                  const Color(0xFF222222),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'Pesquisar',
                ),
              ),
            ),
          ),
        ],
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
      nome: 'Tese Mestrado',
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
        vertical: 42,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Categorias',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore obras por categoria.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 22),

              LayoutBuilder(
                builder:
                    (context, constraints) {
                  final largura =
                      constraints.maxWidth;

                  final colunas =
                  largura >= 900
                      ? 5
                      : largura >= 650
                      ? 3
                      : 2;

                  const espacamento = 12.0;

                  final itemLargura =
                      (largura -
                          ((colunas - 1) *
                              espacamento)) /
                          colunas;

                  return Wrap(
                    spacing: espacamento,
                    runSpacing: espacamento,
                    children: categorias
                        .map(
                          (categoria) =>
                          SizedBox(
                            width: itemLargura,
                            child:
                            _buildCategoriaCard(
                              categoria.nome,
                              categoria.icone,
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

  Widget _buildCategoriaCard(
      String nome,
      IconData icone,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        context.go(
          '/categoria/${Uri.encodeComponent(nome)}',
        );
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
          borderRadius:
          BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius:
                BorderRadius.circular(6),
              ),
              child: Icon(
                icone,
                color: const Color(0xFF444444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
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
  // OBRAS RECENTES
  // ============================================================

  Widget _buildObrasRecentes() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Publicações recentes',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF222222),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Confira as obras publicadas recentemente.',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                            Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/acervo');
                    },
                    child: const Text(
                      'Ver acervo',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

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
                  'Ainda não existem publicações disponíveis.',
                )
              else
                LayoutBuilder(
                  builder:
                      (context, constraints) {
                    final largura =
                        constraints.maxWidth;

                    final colunas =
                    largura >= 900
                        ? 3
                        : largura >= 600
                        ? 2
                        : 1;

                    const espacamento = 14.0;

                    final itemLargura =
                    colunas == 1
                        ? largura
                        : (largura -
                        ((colunas - 1) *
                            espacamento)) /
                        colunas;

                    return Wrap(
                      spacing: espacamento,
                      runSpacing: espacamento,
                      children:
                      _obrasRecentes
                          .map(
                            (obra) =>
                            SizedBox(
                              width:
                              itemLargura,
                              child:
                              _buildObraCard(
                                obra,
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

  Widget _buildObraCard(Obra obra) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(6),
      onTap: () {
        _abrirObra(obra);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
          borderRadius:
          BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFF1F1F1),
                    borderRadius:
                    BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 21,
                    color:
                    Color(0xFF555555),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    obra.titulo,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF222222),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (obra.autor.trim().isNotEmpty)
              Text(
                obra.autor,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),

            const SizedBox(height: 8),

            if (obra.categoria
                .trim()
                .isNotEmpty)
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFF3F3F3),
                  borderRadius:
                  BorderRadius.circular(4),
                ),
                child: Text(
                  obra.categoria,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF555555),
                  ),
                ),
              ),

            const SizedBox(height: 14),

            const Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                Text(
                  'Ver detalhes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF444444),
                  ),
                ),
                SizedBox(width: 5),
                Icon(
                  Icons.arrow_forward,
                  size: 15,
                  color:
                  Color(0xFF444444),
                ),
              ],
            ),
          ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Obras consultadas recentemente',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF222222),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Aceda rapidamente às obras que consultou.',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                            Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(
                        '/historico-obras',
                      );
                    },
                    child: const Text(
                      'Ver histórico',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

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
                LayoutBuilder(
                  builder:
                      (context, constraints) {
                    final largura =
                        constraints.maxWidth;

                    final colunas =
                    largura >= 900
                        ? 3
                        : largura >= 600
                        ? 2
                        : 1;

                    const espacamento = 14.0;

                    final itemLargura =
                    colunas == 1
                        ? largura
                        : (largura -
                        ((colunas - 1) *
                            espacamento)) /
                        colunas;

                    return Wrap(
                      spacing: espacamento,
                      runSpacing: espacamento,
                      children:
                      _consultasRecentes
                          .map(
                            (consulta) =>
                            SizedBox(
                              width:
                              itemLargura,
                              child:
                              _buildConsultaCard(
                                consulta,
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

  Widget _buildConsultaCard(
      HistoricoObra consulta,
      ) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(6),
      onTap: () {
        _abrirConsultaRecente(consulta);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE0E0E0),
          ),
          borderRadius:
          BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                const Color(0xFFF1F1F1),
                borderRadius:
                BorderRadius.circular(5),
              ),
              child: const Icon(
                Icons.history,
                size: 20,
                color: Color(0xFF555555),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    consulta.titulo,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Color(0xFF333333),
                    ),
                  ),

                  if ((consulta.autor ?? '')
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      consulta.autor ?? '',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF777777),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.open_in_new,
              size: 18,
              color: Color(0xFF666666),
            ),
          ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          mensagem,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF777777),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF222222),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 35,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      context.go('/sobre');
                    },
                    child: const Text(
                      'Sobre',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/contacto');
                    },
                    child: const Text(
                      'Contacto',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/termos');
                    },
                    child: const Text(
                      'Termos',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/privacidade');
                    },
                    child: const Text(
                      'Privacidade',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                '© Obra Livre. Todos os direitos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
