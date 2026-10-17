import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/obra.dart';
import 'dialogo_citacao.dart';

/// Leitor PDF com selecção de texto e criação de citações.
class LeitorPdfComCitacao extends StatefulWidget {
  final Obra obra;
  final String urlPdf;
  final String? urlObra;

  const LeitorPdfComCitacao({
    super.key,
    required this.obra,
    required this.urlPdf,
    this.urlObra,
  });

  @override
  State<LeitorPdfComCitacao> createState() =>
      _LeitorPdfComCitacaoState();
}

class _LeitorPdfComCitacaoState
    extends State<LeitorPdfComCitacao> {
  String _trechoSelecionado = '';

  int? _paginaSelecionada;

  bool _carregando = true;
  bool _abrindoCitacao = false;

  String? _erro;

  final PdfViewerController _pdfController =
  PdfViewerController();

  static const BorderRadius _raio =
  BorderRadius.all(Radius.circular(6));

  /// Actualiza o texto seleccionado no PDF.
  void _actualizarSelecao(
      PdfTextSelectionChangedDetails detalhes,
      ) {
    if (!mounted) return;

    setState(() {
      _trechoSelecionado =
          detalhes.selectedText?.trim() ?? '';
    });
  }

  /// Abre o diálogo de criação da citação.
  Future<void> _citarTrecho() async {
    if (_abrindoCitacao) return;

    final trecho = _trechoSelecionado.trim();

    if (trecho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seleccione primeiro o trecho que pretende citar.',
          ),
        ),
      );
      return;
    }

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
        pagina: _paginaSelecionada,
        trecho: trecho,
        url: widget.urlObra,
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
    final tamanho = MediaQuery.sizeOf(context);

    return SizedBox(
      width: tamanho.width * 0.95,
      height: tamanho.height * 0.90,
      child: Column(
        children: [
          // Cabeçalho do leitor.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: _raio,
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf),
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

                // Botão Fechar.
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

          // Área do PDF.
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
                SfPdfViewer.network(
                  widget.urlPdf,
                  controller: _pdfController,
                  enableTextSelection: true,
                  interactionMode:
                  PdfInteractionMode.selection,

                  // PDF carregado.
                  onDocumentLoaded: (_) {
                    if (!mounted) return;

                    setState(() {
                      _carregando = false;
                      _erro = null;
                    });
                  },

                  // Erro ao carregar o PDF.
                  onDocumentLoadFailed: (_) {
                    if (!mounted) return;

                    setState(() {
                      _carregando = false;
                      _erro =
                      'Não foi possível carregar o PDF. '
                          'Verifique a ligação à Internet '
                          'ou tente novamente mais tarde.';
                    });
                  },

                  // Captura o trecho seleccionado.
                  onTextSelectionChanged:
                  _actualizarSelecao,
                ),

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
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLow,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
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

                const SizedBox(height: 6),

                if (_trechoSelecionado.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 90,
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _trechoSelecionado,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton.tonalIcon(
                    onPressed:
                    _trechoSelecionado.trim().isEmpty ||
                        _abrindoCitacao
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
                        horizontal: 10,
                        vertical: 6,
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
    );
  }
}

