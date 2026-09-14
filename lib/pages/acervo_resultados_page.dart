import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/historico_obras_service.dart';
import '../widgets/barra_pesquisa.dart';

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
  HistoricoObrasService();

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obras = [];

  Obra? _obraSelecionada;

  bool _carregando = true;
  bool _pesquisando = false;

  String _filtroCategoria = '';
  String _textoPesquisaAtual = '';

  final List<String> _categorias = const [
    'Todas',
    'Tese Doutoramento',
    'Tese Mestrado',
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
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

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
        await _repository.carregarPorId(_obraId);

        resultado =
        obra != null ? [obra] : [];
      } else if (_categoria.isNotEmpty) {
        resultado =
        await _repository.carregarPorCategoria(
          _categoria,
        );
      } else if (_query.isNotEmpty) {
        resultado =
        await _repository.pesquisar(_query);
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

        if (_obras.isNotEmpty) {
          _obraSelecionada = _obras.first;

          if (_obraId.isNotEmpty) {
            try {
              _obraSelecionada =
                  _obras.firstWhere(
                        (obra) => obra.id == _obraId,
                  );
            } catch (_) {}
          }
        } else {
          _obraSelecionada = null;
        }
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao carregar obras: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];
        _obraSelecionada = null;
        _carregando = false;
      });
    }
  }

  Future<void> _pesquisar() async {
    final texto =
    _pesquisaController.text.trim();

    if (texto.isEmpty) {
      setState(() {
        _textoPesquisaAtual = '';
      });

      await _carregar();
      return;
    }

    if (mounted) {
      setState(() {
        _pesquisando = true;
        _textoPesquisaAtual = texto;
      });
    }

    try {
      final resultado =
      await _repository.pesquisar(texto);

      if (!mounted) return;

      setState(() {
        _obras = resultado;

        _obraSelecionada =
        resultado.isNotEmpty
            ? resultado.first
            : null;

        _pesquisando = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao pesquisar: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];
        _obraSelecionada = null;
        _pesquisando = false;
      });
    }
  }

  Future<void> _limparPesquisa() async {
    _pesquisaController.clear();

    if (mounted) {
      setState(() {
        _textoPesquisaAtual = '';
      });
    }

    await _carregar();
  }

  Future<void> _filtrarCategoria(
      String categoria,
      ) async {
    if (categoria == 'Todas') {
      if (mounted) {
        setState(() {
          _filtroCategoria = '';
          _carregando = true;
        });
      }

      try {
        final resultado =
        await _repository.carregarObras(
          pagina: 1,
          limite: 50,
        );

        if (!mounted) return;

        setState(() {
          _obras = resultado;
          _obraSelecionada =
          resultado.isNotEmpty
              ? resultado.first
              : null;
          _carregando = false;
        });
      } catch (e) {
        debugPrint(
          'ACERVO: erro ao carregar todas as obras: $e',
        );

        if (!mounted) return;

        setState(() {
          _obras = [];
          _obraSelecionada = null;
          _carregando = false;
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        _filtroCategoria = categoria;
        _carregando = true;
      });
    }

    try {
      final resultado =
      await _repository.carregarPorCategoria(
        categoria,
      );

      if (!mounted) return;

      setState(() {
        _obras = resultado;

        _obraSelecionada =
        resultado.isNotEmpty
            ? resultado.first
            : null;

        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao filtrar categoria: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];
        _obraSelecionada = null;
        _carregando = false;
      });
    }
  }

  void _selecionarObra(Obra obra) {
    setState(() {
      _obraSelecionada = obra;
    });
  }

  Future<void> _abrirDocumento(
      Obra obra,
      ) async {
    final url = obra.urlDocumento.trim();

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

        return;
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

      return;
    }

    try {
      await _historicoService.registrarConsulta(
        obraId: obra.id,
      );

      debugPrint(
        'ACERVO: consulta registrada: ${obra.id}',
      );
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao registrar histórico: $e',
      );
    }
  }

  String get _titulo {
    if (_obraId.isNotEmpty &&
        _obras.length == 1) {
      return 'Obra';
    }

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

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xfff7f7f7),
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
        builder: (
            context,
            constraints,
            ) {
          if (constraints.maxWidth < 800) {
            return _buildMobile();
          }

          return _buildDesktop();
        },
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 340,
          decoration:
          const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(
                color: Color(0xffe4e4e4),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  14,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Publicações',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_obras.length}',
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                color: Color(0xffeeeeee),
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
                  const EdgeInsets
                      .symmetric(
                    vertical: 8,
                  ),
                  itemCount:
                  _obras.length,
                  itemBuilder:
                      (context, index) {
                    final obra =
                    _obras[index];

                    final selecionada =
                        _obraSelecionada
                            ?.id ==
                            obra.id;

                    return _PublicacaoListaItem(
                      obra: obra,
                      selecionada:
                      selecionada,
                      onTap: () {
                        _selecionarObra(
                          obra,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              BarraPesquisa(
                controller:
                _pesquisaController,
                hintText:
                'Pesquisar no acervo...',
                pesquisando:
                _pesquisando,
                onPesquisar:
                _pesquisar,
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
                child: PopupMenuButton<String>(
                  tooltip: 'Filtrar',
                  onSelected:
                  _filtrarCategoria,
                  itemBuilder: (context) {
                    return _categorias
                        .map(
                          (categoria) =>
                          PopupMenuItem<
                              String>(
                            value: categoria,
                            child: Row(
                              children: [
                                if ((_filtroCategoria
                                    .isEmpty &&
                                    categoria ==
                                        'Todas') ||
                                    _filtroCategoria ==
                                        categoria)
                                  const Icon(
                                    Icons.check,
                                    size: 18,
                                  ),
                                if ((_filtroCategoria
                                    .isEmpty &&
                                    categoria ==
                                        'Todas') ||
                                    _filtroCategoria ==
                                        categoria)
                                  const SizedBox(
                                    width: 8,
                                  ),
                                Text(categoria),
                              ],
                            ),
                          ),
                    )
                        .toList();
                  },
                  child: Container(
                    height: 42,
                    width: 48,
                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(
                        6,
                      ),
                      border: Border.all(
                        color:
                        const Color(
                          0xffdddddd,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      size: 21,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _obraSelecionada == null
                    ? _buildSemSelecao()
                    : SingleChildScrollView(
                  padding:
                  const EdgeInsets.all(
                    30,
                  ),
                  child:
                  _buildDetalhesObra(
                    _obraSelecionada!,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetalhesObra(
      Obra obra,
      ) {
    return Center(
      child: ConstrainedBox(
        constraints:
        const BoxConstraints(
          maxWidth: 900,
        ),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(6),
            border: Border.all(
              color:
              const Color(0xffe2e2e2),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                obra.titulo,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight:
                  FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                obra.autor,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon:
                    Icons.category_outlined,
                    texto: obra.categoria,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(
                color:
                Color(0xffeeeeee),
              ),
              const SizedBox(height: 24),
              if (obra.descricao != null &&
                  obra.descricao!
                      .trim()
                      .isNotEmpty) ...[
                const Text(
                  'Descrição',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  obra.descricao!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
              ],
              SizedBox(
                height: 46,
                child:
                ElevatedButton.icon(
                  onPressed: () =>
                      _abrirDocumento(
                        obra,
                      ),
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 18,
                  ),
                  label: const Text(
                    'Abrir documento',
                  ),
                  style: ElevatedButton
                      .styleFrom(
                    elevation: 0,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 20,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemSelecao() {
    return const Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 42,
            color: Colors.black26,
          ),
          SizedBox(height: 12),
          Text(
            'Selecione uma publicação',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return Column(
      children: [
        BarraPesquisa(
          controller:
          _pesquisaController,
          hintText:
          'Pesquisar no acervo...',
          pesquisando:
          _pesquisando,
          onPesquisar:
          _pesquisar,
          onLimpar:
          _limparPesquisa,
        ),
        Container(
          color: Colors.white,
          padding:
          const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            10,
          ),
          alignment:
          Alignment.centerRight,
          child: PopupMenuButton<String>(
            tooltip: 'Filtrar',
            onSelected:
            _filtrarCategoria,
            itemBuilder: (context) {
              return _categorias
                  .map(
                    (categoria) =>
                    PopupMenuItem<String>(
                      value: categoria,
                      child: Row(
                        children: [
                          if ((_filtroCategoria
                              .isEmpty &&
                              categoria ==
                                  'Todas') ||
                              _filtroCategoria ==
                                  categoria)
                            const Icon(
                              Icons.check,
                              size: 18,
                            ),
                          if ((_filtroCategoria
                              .isEmpty &&
                              categoria ==
                                  'Todas') ||
                              _filtroCategoria ==
                                  categoria)
                            const SizedBox(
                              width: 8,
                            ),
                          Text(categoria),
                        ],
                      ),
                    ),
              )
                  .toList();
            },
            child: Container(
              height: 42,
              width: 48,
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(6),
                border: Border.all(
                  color:
                  const Color(0xffdddddd),
                ),
                color: Colors.white,
              ),
              child: const Icon(
                Icons.filter_list,
                size: 21,
              ),
            ),
          ),
        ),
        if (_obras.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Nenhuma publicação encontrada.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.all(16),
              itemCount: _obras.length,
              itemBuilder:
                  (context, index) {
                final obra =
                _obras[index];

                return _PublicacaoListaItem(
                  obra: obra,
                  selecionada:
                  _obraSelecionada?.id ==
                      obra.id,
                  mobile: true,
                  onTap: () {
                    _selecionarObra(
                      obra,
                    );

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled:
                      true,
                      backgroundColor:
                      Colors.white,
                      builder: (_) {
                        return SafeArea(
                          child:
                          SingleChildScrollView(
                            padding:
                            const EdgeInsets
                                .all(24),
                            child:
                            _buildDetalhesObra(
                              obra,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PublicacaoListaItem
    extends StatelessWidget {
  final Obra obra;
  final bool selecionada;
  final bool mobile;
  final VoidCallback onTap;

  const _PublicacaoListaItem({
    required this.obra,
    required this.selecionada,
    required this.onTap,
    this.mobile = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: selecionada
          ? const Color(0xfff1f1f1)
          : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(
                color: Color(0xffeeeeee),
              ),
              left: selecionada
                  ? const BorderSide(
                color: Colors.black87,
                width: 3,
              )
                  : BorderSide.none,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                obra.titulo,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: selecionada
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                obra.autor,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip
    extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _InfoChip({
    required this.icon,
    required this.texto,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xfff3f3f3),
        borderRadius:
        BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.black54,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

