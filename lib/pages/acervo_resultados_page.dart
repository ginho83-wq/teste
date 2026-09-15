import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../models/historico_obra.dart';
import '../repositories/obras_repository.dart';
import '../services/historico_obras_service.dart';
import '../widgets/barra_pesquisa.dart';
import '../widgets/detalhes_obra_dialog.dart';
import '../widgets/historico_lista_item.dart';
import '../widgets/obra_lista_item.dart';
import 'historico_obras_page.dart';

class AcervoResultadosPage extends StatefulWidget {
  final String? query;
  final String? categoria;
  final String? obraId;

  const AcervoResultadosPage({
    super.key,
    this.query,
    this.categoria,
    this.obraId,
  });

  @override
  State<AcervoResultadosPage> createState() =>
      _AcervoResultadosPageState();
}

class _AcervoResultadosPageState
    extends State<AcervoResultadosPage> {
  final ObrasRepository _repository =
      ObrasRepository.instancia;

  final HistoricoObrasService _historicoService =
      HistoricoObrasService.instancia;

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obras = [];

  List<HistoricoObra> _historico = [];

  bool _carregando = true;

  bool _carregandoHistorico = true;

  String _filtroCategoria = '';

  String _textoPesquisaAtual = '';

  final List<String> _categorias = const [
    'Todas',
    'Tese Doutoramento',
    'Dissertação de Mestrado',
    'Monografia',
    'Artigos Científicos',
    'Literatura',
  ];

  String get _query =>
      widget.query?.trim() ?? '';

  String get _categoria =>
      widget.categoria?.trim() ?? '';

  String get _obraId =>
      widget.obraId?.trim() ?? '';

  @override
  void initState() {
    super.initState();

    _pesquisaController.text = _query;

    _textoPesquisaAtual = _query;

    _filtroCategoria = _categoria;

    _carregar();

    _carregarHistorico();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();

    super.dispose();
  }

  // =========================================================
  // CARREGAR OBRAS
  // =========================================================

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      List<Obra> resultado;

      if (_obraId.isNotEmpty) {
        final obra =
        await _repository.carregarPorId(
          _obraId,
        );

        resultado =
        obra != null ? [obra] : [];
      } else if (_categoria.isNotEmpty) {
        resultado =
        await _repository.carregarPorCategoria(
          _categoria,
        );
      } else if (_query.isNotEmpty) {
        resultado =
        await _repository.pesquisar(
          _query,
        );
      } else {
        resultado =
        await _repository.carregarObras(
          pagina: 1,
          limite: 50,
        );
      }

      if (!mounted) return;

      setState(() {
        _obras = resultado;

        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao carregar obras: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];

        _carregando = false;
      });
    }
  }

  // =========================================================
  // CARREGAR HISTÓRICO
  // =========================================================

  Future<void> _carregarHistorico() async {
    if (mounted) {
      setState(() {
        _carregandoHistorico = true;
      });
    }

    try {
      final historico =
      await _historicoService
          .obterConsultasRecentes(
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _historico = historico;

        _carregandoHistorico = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao carregar histórico: $e',
      );

      if (!mounted) return;

      setState(() {
        _historico = [];

        _carregandoHistorico = false;
      });
    }
  }

  // =========================================================
  // PESQUISA
  // =========================================================

  Future<void> _pesquisar() async {
    final texto =
    _pesquisaController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    context.go(
      '/acervo/pesquisa/${Uri.encodeComponent(texto)}',
    );
  }

  Future<void> _limparPesquisa() async {
    _pesquisaController.clear();

    if (mounted) {
      setState(() {
        _textoPesquisaAtual = '';
      });
    }

    context.go('/acervo');
  }

  // =========================================================
  // FILTRO DE CATEGORIA
  // =========================================================

  void _filtrarCategoria(
      String categoria,
      ) {
    if (categoria == 'Todas') {
      context.go('/acervo');

      return;
    }

    context.go(
      '/categoria/${Uri.encodeComponent(categoria)}',
    );
  }

  // =========================================================
  // REGISTRAR CONSULTA
  // =========================================================

  Future<void> _registrarConsulta(
      Obra obra,
      ) async {
    try {
      await _historicoService.registrarConsulta(
        obraId: obra.id,
      );

      debugPrint(
        'ACERVO: consulta registrada: ${obra.id}',
      );

      await _carregarHistorico();
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao registrar histórico: $e',
      );
    }
  }

  // =========================================================
  // ABRIR DETALHES
  // =========================================================

  Future<void> _abrirDetalhes(
      Obra obra,
      ) async {
    await _registrarConsulta(obra);

    if (!mounted) return;

    await mostrarDetalhesObraDialog(
      context,
      obra: obra,
      mostrarAbrir: true,
      onAbrir: () =>
          _abrirDocumento(obra),
    );
  }

  // =========================================================
  // ABRIR DOCUMENTO
  // =========================================================

  Future<void> _abrirDocumento(
      Obra obra,
      ) async {
    final url =
        obra.urlDocumento?.trim() ?? '';

    if (url.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Esta obra não possui documento disponível.',
          ),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'O endereço do documento é inválido.',
          ),
        ),
      );

      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );

      debugPrint(
        'ACERVO: documento aberto: $abriu',
      );

      if (!abriu) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o documento.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao abrir documento: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ABRIR HISTÓRICO COMPLETO
  // =========================================================

  Future<void> _abrirHistoricoCompleto() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const HistoricoObrasPage(),
      ),
    );

    await _carregarHistorico();
  }

  // =========================================================
  // REMOVER DO HISTÓRICO
  // =========================================================

  Future<void> _removerHistorico(
      HistoricoObra obra,
      ) async {
    try {
      await _historicoService.removerConsulta(
        id: obra.id,
      );

      if (!mounted) return;

      setState(() {
        _historico.removeWhere(
              (item) => item.id == obra.id,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível remover a consulta.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // TÍTULO
  // =========================================================

  String get _titulo {
    if (_textoPesquisaAtual.isNotEmpty) {
      return 'Resultados para "$_textoPesquisaAtual"';
    }

    if (_filtroCategoria.isNotEmpty) {
      return _filtroCategoria;
    }

    if (_categoria.isNotEmpty) {
      return _categoria;
    }

    if (_query.isNotEmpty) {
      return 'Resultados para "$_query"';
    }

    return 'Acervo';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xfff5f6f8),
      appBar: AppBar(
        title: Text(
          _titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : LayoutBuilder(
        builder:
            (context, constraints) {
          if (constraints.maxWidth <
              800) {
            return _buildMobile();
          }

          return _buildDesktop();
        },
      ),
    );
  }

  // =========================================================
  // DESKTOP
  // =========================================================

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 340,
          decoration:
          const BoxDecoration(
            color: Color(0xfff0f2f5),
            border: Border(
              right: BorderSide(
                color: Color(0xffdfe2e6),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration:
                const BoxDecoration(
                  color: Color(0xff1565C0),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Publicações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration:
                      BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.15),
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Text(
                        '${_obras.length}',
                        style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _obras.isEmpty
                    ? const Center(
                  child: Padding(
                    padding:
                    EdgeInsets.all(20),
                    child: Text(
                      'Nenhuma publicação encontrada.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color:
                        Colors.black54,
                      ),
                    ),
                  ),
                )
                    : ListView.builder(
                  padding:
                  const EdgeInsets.only(
                    top: 8,
                    bottom: 8,
                  ),
                  itemCount:
                  _obras.length,
                  itemBuilder:
                      (context, index) {
                    final obra =
                    _obras[index];

                    return ObraListaItem(
                      obra: obra,
                      onTap: () =>
                          _abrirDetalhes(
                            obra,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ===================================================
        // ÁREA CENTRAL
        // ===================================================

        Expanded(
          child: Column(
            children: [
              BarraPesquisa(
                controller:
                _pesquisaController,
                hintText:
                'Pesquisar no acervo...',
                onPesquisar: _pesquisar,
                onLimpar:
                _limparPesquisa,
              ),

              Container(
                color: Colors.white,
                padding:
                const EdgeInsets.only(
                  right: 24,
                  bottom: 10,
                ),
                alignment:
                Alignment.centerRight,
                child:
                _buildFiltroCategoria(),
              ),

              Expanded(
                child:
                _buildHistoricoCentral(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // HISTÓRICO CENTRAL
  // =========================================================

  Widget _buildHistoricoCentral() {
    if (_carregandoHistorico) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
      const EdgeInsets.fromLTRB(
        24,
        18,
        24,
        24,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Consultados recentemente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
              if (_historico.isNotEmpty)
                TextButton(
                  onPressed:
                  _abrirHistoricoCompleto,
                  child:
                  const Text('Ver tudo'),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _historico.isEmpty
                ? const Center(
              child: Text(
                'Ainda não existem obras consultadas.',
                style: TextStyle(
                  color:
                  Colors.black54,
                ),
              ),
            )
                : ListView.builder(
              itemCount:
              _historico.length,
              itemBuilder:
                  (context, index) {
                final obra =
                _historico[index];

                return HistoricoListaItem(
                  obra: obra,
                  onAbrir: () =>
                      _abrirHistoricoDocumento(
                        obra,
                      ),
                  onRemover: () =>
                      _removerHistorico(
                        obra,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ABRIR DOCUMENTO DO HISTÓRICO
  // =========================================================

  Future<void> _abrirHistoricoDocumento(
      HistoricoObra obra,
      ) async {
    final url =
        obra.urlDocumento?.trim() ?? '';

    if (url.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Esta obra não possui documento disponível.',
          ),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'O endereço do documento é inválido.',
          ),
        ),
      );

      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );

      if (!abriu && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o documento.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao abrir documento do histórico: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // FILTRO DE CATEGORIA
  // =========================================================

  Widget _buildFiltroCategoria() {
    return PopupMenuButton<String>(
      tooltip: 'Filtrar por categoria',
      onSelected: _filtrarCategoria,
      itemBuilder: (context) {
        return _categorias.map(
              (categoria) {
            final selecionada =
                (_filtroCategoria.isEmpty &&
                    categoria == 'Todas') ||
                    _filtroCategoria ==
                        categoria;

            return PopupMenuItem<String>(
              value: categoria,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: selecionada
                        ? const Icon(
                      Icons.check,
                      size: 18,
                    )
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Text(categoria),
                ],
              ),
            );
          },
        ).toList();
      },
      child: Container(
        height: 42,
        width: 48,
        decoration: BoxDecoration(
          borderRadius:
          BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xffd8dadd),
          ),
          color: Colors.white,
        ),
        child: const Icon(
          Icons.filter_list,
          size: 21,
          color: Colors.black87,
        ),
      ),
    );
  }

  // =========================================================
  // MOBILE
  // =========================================================

  Widget _buildMobile() {
    return Column(
      children: [
        BarraPesquisa(
          controller:
          _pesquisaController,
          hintText:
          'Pesquisar no acervo...',
          onPesquisar: _pesquisar,
          onLimpar:
          _limparPesquisa,
        ),

        Container(
          width: double.infinity,
          color: Colors.white,
          padding:
          const EdgeInsets.only(
            right: 16,
            bottom: 10,
          ),
          alignment:
          Alignment.centerRight,
          child:
          _buildFiltroCategoria(),
        ),

        Expanded(
          child: _buildMobileConteudo(),
        ),
      ],
    );
  }

  Widget _buildMobileConteudo() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration:
            const BoxDecoration(
              color: Color(0xff1565C0),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Publicações',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${_obras.length}',
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _obras.isEmpty
                ? const Center(
              child: Padding(
                padding:
                EdgeInsets.all(20),
                child: Text(
                  'Nenhuma publicação encontrada.',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color:
                    Colors.black54,
                  ),
                ),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.only(
                top: 8,
                bottom: 8,
              ),
              itemCount:
              _obras.length,
              itemBuilder:
                  (context, index) {
                final obra =
                _obras[index];

                return ObraListaItem(
                  obra: obra,
                  mobile: true,
                  onTap: () =>
                      _abrirDetalhes(
                        obra,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HISTÓRICO MOBILE
  // =========================================================

  Widget _buildHistoricoMobile() {
    if (_carregandoHistorico) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
      const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Consultados recentemente',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
              if (_historico.isNotEmpty)
                TextButton(
                  onPressed:
                  _abrirHistoricoCompleto,
                  child:
                  const Text('Ver tudo'),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _historico.isEmpty
                ? const Center(
              child: Text(
                'Ainda não existem obras consultadas.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  Colors.black54,
                ),
              ),
            )
                : ListView.builder(
              itemCount:
              _historico.length,
              itemBuilder:
                  (context, index) {
                final obra =
                _historico[index];

                return HistoricoListaItem(
                  obra: obra,
                  onAbrir: () =>
                      _abrirHistoricoDocumento(
                        obra,
                      ),
                  onRemover: () =>
                      _removerHistorico(
                        obra,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
