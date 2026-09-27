import 'package:flutter/material.dart';

import '../models/obra.dart';

class ObraListaItem extends StatelessWidget {
  final Obra obra;
  final VoidCallback onTap;
  final bool mobile;

  const ObraListaItem({
    super.key,
    required this.obra,
    required this.onTap,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    // ===============================================================
    // 2ª LINHA — AUTOR + ANO DA OBRA + DESCRIÇÃO
    // ===============================================================

    final List<String> segundaLinha = [];

    if (obra.autor.trim().isNotEmpty) {
      segundaLinha.add(
        obra.autor.trim(),
      );
    }

    if (obra.anoObra != null) {
      segundaLinha.add(
        '(${obra.anoObra})',
      );
    }

    if ((obra.descricao ?? '')
        .trim()
        .isNotEmpty) {
      segundaLinha.add(
        obra.descricao!.trim(),
      );
    }

    // ===============================================================
    // 3ª LINHA — CATEGORIA + DATA + PDF + PÁGINAS + TAMANHO
    // ===============================================================

    final List<String> terceiraLinha = [];

    if (obra.categoria
        .trim()
        .isNotEmpty) {
      terceiraLinha.add(
        obra.categoria.trim(),
      );
    }

    terceiraLinha.add(
      'Publicada em ${obra.dataPublicacao.year}',
    );

    terceiraLinha.add(
      'PDF',
    );

    // ===============================================================
    // NÚMERO DE PÁGINAS
    // ===============================================================

    if (obra.numeroPaginas != null &&
        obra.numeroPaginas! > 0) {
      terceiraLinha.add(
        '${obra.numeroPaginas} páginas',
      );
    }

    // ===============================================================
    // TAMANHO DO PDF
    // ===============================================================

    if (obra.tamanhoArquivoBytes != null &&
        obra.tamanhoArquivoBytes! > 0) {
      terceiraLinha.add(
        _formatarTamanho(
          obra.tamanhoArquivoBytes!,
        ),
      );
    }

    final String textoSegundaLinha =
    segundaLinha.join(', ');

    final String textoTerceiraLinha =
    terceiraLinha.join(', ');

    final bool possuiCapa =
        obra.urlCapa != null &&
            obra.urlCapa!
                .trim()
                .isNotEmpty;

    // ===============================================================
    // DIMENSÕES DA CAPA
    // ===============================================================

    final double larguraCapa =
    mobile ? 62 : 72;

    final double alturaCapa =
    mobile ? 82 : 88;

    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor:
      Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor:
        const Color(0xfff8f9fa),
        splashColor:
        const Color(0xfff1f3f4),
        highlightColor:
        Colors.transparent,
        child: Container(
          width: double.infinity,
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: mobile ? 8 : 12,
            right: mobile ? 8 : 12,
            top: 14,
            bottom: 14,
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // =====================================================
              // CAPA
              // =====================================================

              SizedBox(
                width: larguraCapa,
                height: alturaCapa,
                child: possuiCapa
                    ? ClipRRect(
                  borderRadius:
                  BorderRadius.circular(4),
                  child: Image.network(
                    obra.urlCapa!,
                    fit: BoxFit.cover,
                    filterQuality:
                    FilterQuality.medium,
                    errorBuilder: (
                        context,
                        error,
                        stackTrace,
                        ) {
                      return _placeholderCapa();
                    },
                  ),
                )
                    : _placeholderCapa(),
              ),

              const SizedBox(
                width: 14,
              ),

              // =====================================================
              // INFORMAÇÕES DA OBRA
              // =====================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    // =================================================
                    // 1. TÍTULO
                    // =================================================

                    Text(
                      obra.titulo,
                      softWrap: true,
                      style:
                      const TextStyle(
                        fontSize: 17,
                        height: 1.4,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xff1a73e8),
                        decoration:
                        TextDecoration
                            .underline,
                        decorationColor:
                        Color(0xff1a73e8),
                        decorationThickness:
                        1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // =================================================
                    // 2. AUTOR + ANO + RESUMO
                    // =================================================

                    if (textoSegundaLinha
                        .isNotEmpty)
                      Text(
                        textoSegundaLinha,
                        softWrap: true,
                        maxLines: 3,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight:
                          FontWeight.w400,
                          color:
                          Color(0xff5f6368),
                        ),
                      ),

                    const SizedBox(
                      height: 4,
                    ),

                    // =================================================
                    // 3. CATEGORIA + DATA + PDF
                    //    + PÁGINAS + TAMANHO
                    // =================================================

                    Text(
                      textoTerceiraLinha,
                      softWrap: true,
                      style:
                      const TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        fontWeight:
                        FontWeight.w400,
                        color:
                        Color(0xff5f6368),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // PLACEHOLDER QUANDO NÃO EXISTE CAPA
  // ===============================================================

  Widget _placeholderCapa() {
    return Container(
      decoration: BoxDecoration(
        color:
        const Color(0xfff1f3f4),
        borderRadius:
        BorderRadius.circular(4),
        border: Border.all(
          color:
          const Color(0xffdadce0),
          width: 1,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.picture_as_pdf_outlined,
          size: 28,
          color:
          Color(0xff5f6368),
        ),
      ),
    );
  }

  // ===============================================================
  // FORMATAÇÃO DO TAMANHO DO PDF
  // ===============================================================

  static String _formatarTamanho(
      int bytes,
      ) {
    const unidades = [
      'B',
      'KB',
      'MB',
      'GB',
      'TB',
    ];

    double tamanho =
    bytes.toDouble();

    int indice = 0;

    while (tamanho >= 1024 &&
        indice <
            unidades.length - 1) {
      tamanho /= 1024;
      indice++;
    }

    if (indice == 0) {
      return '${tamanho.toStringAsFixed(0)} '
          '${unidades[indice]}';
    }

    return '${tamanho.toStringAsFixed(1)} '
        '${unidades[indice]}';
  }
}
