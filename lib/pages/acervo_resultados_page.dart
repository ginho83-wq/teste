import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/historico_obras_service.dart';
import '../widgets/barra_pesquisa.dart';
import '../widgets/detalhes_obra_dialog.dart';

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

  // ==========================================================
  // CARREGAR OBRAS
  // ==========================================================

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

  // ==========================================================
  // PESQUISA
  // ==========================================================

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
        _pesquisando = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao pesquisar: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];
        _pesquisando = false;
      });
    }
  }

  // ==========================================================
  // LIMPAR PESQUISA
  // ==========================================================

  Future<void> _limparPesquisa() async {
    _pesquisaController.clear();

    if (mounted) {
      setState(() {
        _textoPesquisaAtual = '';
      });
    }

    await _carregar();
  }

  // ==========================================================
  // FILTRO POR CATEGORIA
  // ==========================================================

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
          _carregando = false;
        });
      } catch (e) {
        debugPrint(
          'ACERVO: erro ao carregar todas as obras: $e',
        );

        if (!mounted) return;

        setState(() {
          _obras = [];
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
        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao filtrar categoria: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];
        _carregando = false;
      });
    }
  }

  // ==========================================================
  // ABRIR DETALHES
  // ==========================================================
  //
  // IMPORTANTE:
  // Os detalhes NÃO são construídos nesta página.
  //
  // É utilizado exatamente o diálogo reutilizável
  // de detalhes existente em:
  //
  // widgets/detalhes_dialog.dart
  //
  // ==========================================================

  Future<void> _abrirDetalhes(
      Obra obra,
      ) async {
    await mostrarDetalhesObraDialog(
      context,
      obra: obra,
      mostrarAbrir: true,
      onAbrir: () => _abrirDocumento(obra),
    );
  }

  // ==========================================================
  // ABRIR DOCUMENTO
  // ==========================================================

  Future<void> _abrirDocumento(
      Obra obra,
      ) async {
    final url =
    obra.urlDocumento.trim();

    if (url.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
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

      ScaffoldMessenger.of(context).showSnackBar(
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

        ScaffoldMessenger.of(context).showSnackBar(
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // REGISTRAR NO HISTÓRICO
    // ========================================================

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

  // ==========================================================
  // TÍTULO
  // ==========================================================

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

  // ==========================================================
  // BUILD
  // ==========================================================

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
        child: CircularProgressIndicator(),
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

  // ==========================================================
  // DESKTOP
  // ==========================================================

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,

      children: [
        // ======================================================
        // PAINEL ESQUERDO
        // ======================================================

        Container(
          width: 340,

          decoration: const BoxDecoration(
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
              // ==================================================
              // CABEÇALHO PUBLICAÇÕES
              // ==================================================

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

              // ==================================================
              // LISTA
              // ==================================================

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

                    return _PublicacaoListaItem(
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

        // ======================================================
        // ÁREA DIREITA
        // ======================================================

        Expanded(
          child: Column(
            children: [
              // ==================================================
              // PESQUISA
              // ==================================================

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

              // ==================================================
              // FILTRO
              // ==================================================

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

              // ==================================================
              // ÁREA CENTRAL VAZIA
              // ==================================================
              //
              // NÃO existe nenhum detalhe de obra aqui.
              //
              // O detalhe só aparece quando o utilizador
              // clica numa publicação e o diálogo reutilizável
              // é aberto.
              // ==================================================

              const Expanded(
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FILTRO
  // ==========================================================

  Widget _buildFiltroCategoria() {
    return PopupMenuButton<String>(
      tooltip:
      'Filtrar por categoria',

      onSelected:
      _filtrarCategoria,

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
            color:
            const Color(0xffd8dadd),
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

  // ==========================================================
  // MOBILE
  // ==========================================================

  Widget _buildMobile() {
    return Column(
      children: [
        // ======================================================
        // PESQUISA
        // ======================================================

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

        // ======================================================
        // FILTRO
        // ======================================================

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

          child:
          _buildFiltroCategoria(),
        ),

        // ======================================================
        // LISTA
        // ======================================================

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

              itemCount:
              _obras.length,

              itemBuilder:
                  (context, index) {
                final obra =
                _obras[index];

                return _PublicacaoListaItem(
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
    );
  }
}

// ==========================================================
// ITEM DA LISTA DE PUBLICAÇÕES
// ==========================================================

class _PublicacaoListaItem
    extends StatelessWidget {
  final Obra obra;
  final bool mobile;
  final VoidCallback onTap;

  const _PublicacaoListaItem({
    required this.obra,
    required this.onTap,
    this.mobile = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      const Color(0xfff0f2f5),

      child: InkWell(
        onTap: onTap,

        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),

          decoration:
          const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                Color(0xffdfe2e6),
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // ==================================================
              // TÍTULO
              // ==================================================

              Text(
                obra.titulo,

                maxLines: 2,

                overflow:
                TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight:
                  FontWeight.w500,
                  color:
                  Colors.black87,
                ),
              ),

              const SizedBox(height: 5),

              // ==================================================
              // AUTOR
              // ==================================================

              Text(
                obra.autor,

                maxLines: 1,

                overflow:
                TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 12.5,
                  color:
                  Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
