import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/obra.dart';
import 'dialogo_citacao.dart';

/// Leitor PDF com selecção de texto e criação de citações.
class LeitorPdfComCitacao extends StatefulWidget {
  final Obra obra;
  final String urlPdf;
  final String? urlObra;

  /// Indica se o leitor deve iniciar em ecrã inteiro.
  final bool modoEcraInteiro;

  const LeitorPdfComCitacao({
    super.key,
    required this.obra,
    required this.urlPdf,
    this.urlObra,
    this.modoEcraInteiro = false,
  });

  @override
  State<LeitorPdfComCitacao> createState() =>
      _LeitorPdfComCitacaoState();
}

class _LeitorPdfComCitacaoState
    extends State<LeitorPdfComCitacao> {
  final PdfViewerController _pdfController =
  PdfViewerController();

  String _trechoSelecionado = '';

  int _paginaAtual = 1;
  int _totalPaginas = 0;

  bool _carregando = true;
  bool _abrindoCitacao = false;

  String? _erro;

  static const BorderRadius _raio =
  BorderRadius.all(Radius.circular(6));

  /// Abre o leitor numa rota que ocupa todo o ecrã.
  void _alternarMaximizacao() {
    if (widget.modoEcraInteiro) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return LeitorPdfComCitacao(
            obra: widget.obra,
            urlPdf: widget.urlPdf,
            urlObra: widget.urlObra,
            modoEcraInteiro: true,
          );
        },
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// Actualiza o trecho seleccionado no PDF.
  void _actualizarSelecao(
      PdfTextSelectionChangedDetails detalhes,
      ) {
    if (!mounted) return;

    setState(() {
      _trechoSelecionado =
          detalhes.selectedText?.trim() ?? '';
    });
  }

  /// Actualiza o indicador da página actual.
  void _actualizarPagina(
      PdfPageChangedDetails detalhes,
      ) {
    if (!mounted) return;

    setState(() {
      _paginaAtual = detalhes.newPageNumber;
    });
  }

  /// Regista o carregamento do documento PDF.
  void _documentoCarregado(
      PdfDocumentLoadedDetails detalhes,
      ) {
    if (!mounted) return;

    setState(() {
      _carregando = false;
      _erro = null;
      _totalPaginas = detalhes.document.pages.count;
      _paginaAtual = _pdfController.pageNumber;
    });
  }

  /// Apresenta uma mensagem quando o PDF falha.
  void _documentoFalhou(
      PdfDocumentLoadFailedDetails detalhes,
      ) {
    if (!mounted) return;

    setState(() {
      _carregando = false;
      _erro =
      'Não foi possível carregar o PDF.\n\n'
          'Verifique a ligação à Internet ou tente '
          'novamente mais tarde.';
    });
  }

  /// Acrescenta reticências quando o trecho parece incompleto.
  String _formatarTrechoParaCitacao(String texto) {
    String trecho = texto.trim();

    if (trecho.isEmpty) return '';

    trecho = trecho.replaceAll(RegExp(r'\s+'), ' ');

    final bool temReticenciasInicio =
        trecho.startsWith('...') ||
            trecho.startsWith('…');

    final bool temReticenciasFim =
        trecho.endsWith('...') ||
            trecho.endsWith('…');

    final bool pareceInicioParcial =
        RegExp(r'^[a-záàâãéèêíóôõúç0-9,;:]')
            .hasMatch(trecho) &&
            !temReticenciasInicio;

    final bool pareceFimParcial =
        !RegExp(r'[.!?…»”"\)\]]$').hasMatch(trecho) &&
            !temReticenciasFim;

    if (pareceInicioParcial) {
      trecho = '...$trecho';
    }

    if (pareceFimParcial) {
      trecho = '$trecho...';
    }

    return trecho;
  }

  /// Abre o diálogo de criação da citação.
  Future<void> _citarTrecho() async {
    if (_abrindoCitacao) return;

    final String trechoOriginal =
    _trechoSelecionado.trim();

    if (trechoOriginal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seleccione primeiro o trecho que pretende citar.',
          ),
        ),
      );
      return;
    }

    final String trechoFormatado =
    _formatarTrechoParaCitacao(trechoOriginal);

    setState(() {
      _abrindoCitacao = true;
    });

    try {
      await DialogoCitacao.mostrar(
        context,
        autor: widget.obra.autor,
        titulo: widget.obra.titulo,
        ano: (widget.obra.anoObra ??
            widget.obra.dataPublicacao.year)
            .toString(),
        pagina: _paginaAtual,
        trecho: trechoFormatado,
        url: widget.urlObra,

        // Identificador da obra para a notificação por email.
        obraId: widget.obra.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir a criação da citação.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _abrindoCitacao = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Material(
      color: tema.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Cabeçalho do leitor.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4FF),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFF245A81),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.obra.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Botão maximizar/restaurar.
                  IconButton(
                    tooltip: widget.modoEcraInteiro
                        ? 'Restaurar tamanho'
                        : 'Maximizar leitor',
                    onPressed: _alternarMaximizacao,
                    icon: Icon(
                      widget.modoEcraInteiro
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                    ),
                  ),

                  // Botão fechar.
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Área de visualização do PDF.
            Expanded(
              child: _erro != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _erro!,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : Stack(
                children: [
                  // Fundo visível entre as páginas.
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0xFFE2E5E9),
                    ),
                  ),

                  // Leitor PDF.
                  Positioned.fill(
                    child: SfPdfViewer.network(
                      widget.urlPdf,
                      controller: _pdfController,
                      enableTextSelection: true,
                      interactionMode:
                      PdfInteractionMode.selection,
                      pageSpacing: 12,
                      onDocumentLoaded:
                      _documentoCarregado,
                      onDocumentLoadFailed:
                      _documentoFalhou,
                      onPageChanged:
                      _actualizarPagina,
                      onTextSelectionChanged:
                      _actualizarSelecao,
                    ),
                  ),

                  // Número da página actual.
                  if (!_carregando && _erro == null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IgnorePointer(
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius:
                            BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'Página $_paginaAtual'
                                ' de $_totalPaginas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Indicador de carregamento.
                  if (_carregando)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),

            // Área de criação da citação.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerLow,
                border: Border(
                  top: BorderSide(
                    color: tema.dividerColor,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _trechoSelecionado.isEmpty
                        ? 'Seleccione um trecho do PDF para criar uma citação.'
                        : 'Trecho seleccionado:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (_trechoSelecionado.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 80,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _trechoSelecionado,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed:
                      _trechoSelecionado.trim().isEmpty ||
                          _abrindoCitacao ||
                          _carregando
                          ? null
                          : _citarTrecho,
                      icon: const Icon(
                        Icons.format_quote,
                        size: 16,
                      ),
                      label: Text(
                        _abrindoCitacao
                            ? 'A abrir...'
                            : 'Citar',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

