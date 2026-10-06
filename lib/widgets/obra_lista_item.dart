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
    // 2ª LINHA — DESCRIÇÃO
    // ===============================================================

    final String textoDescricao =
    (obra.descricao ?? '').trim();

    // ===============================================================
    // 3ª LINHA — AUTOR + CATEGORIA + ANO + DATA + PDF
    //              + PÁGINAS + TAMANHO
    // ===============================================================

    final List<String> terceiraLinha = [];

    if (obra.autor.trim().isNotEmpty) {
      terceiraLinha.add(
        obra.autor.trim(),
      );
    }

    if (obra.categoria.trim().isNotEmpty) {
      terceiraLinha.add(
        obra.categoria.trim(),
      );
    }

    if (obra.anoObra != null) {
      terceiraLinha.add(
        '${obra.anoObra}',
      );
    }

    terceiraLinha.add(
      'Publicada em ${obra.dataPublicacao.year}',
    );

    terceiraLinha.add(
      'PDF',
    );

    if (obra.numeroPaginas != null &&
        obra.numeroPaginas! > 0) {
      terceiraLinha.add(
        '${obra.numeroPaginas} páginas',
      );
    }

    if (obra.tamanhoArquivoBytes != null &&
        obra.tamanhoArquivoBytes! > 0) {
      terceiraLinha.add(
        _formatarTamanho(
          obra.tamanhoArquivoBytes!,
        ),
      );
    }

    final String textoTerceiraLinha =
    terceiraLinha.join(', ');

    // ===============================================================
    // ITEM DA OBRA — SEM CAPA
    // ===============================================================

    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xfff8f9fa),
        splashColor: const Color(0xfff1f3f4),
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: mobile ? 8 : 12,
            right: mobile ? 8 : 12,
            top: 14,
            bottom: 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // 1. TÍTULO
              // =====================================================

              Text(
                obra.titulo,
                softWrap: true,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1a73e8),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xff1a73e8),
                  decorationThickness: 1.2,
                ),
              ),

              const SizedBox(height: 5),

              // =====================================================
              // 2. DESCRIÇÃO
              // =====================================================

              if (textoDescricao.isNotEmpty)
                Text(
                  textoDescricao,
                  softWrap: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff5f6368),
                  ),
                ),

              const SizedBox(height: 4),

              // =====================================================
              // 3. AUTOR + CATEGORIA + ANO + DATA + PDF
              //    + PÁGINAS + TAMANHO
              // =====================================================

              if (textoTerceiraLinha.isNotEmpty)
                Text(
                  textoTerceiraLinha,
                  softWrap: true,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff5f6368),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // FORMATAÇÃO DO TAMANHO DO PDF
  // ===============================================================

  static String _formatarTamanho(int bytes) {
    const unidades = [
      'B',
      'KB',
      'MB',
      'GB',
      'TB',
    ];

    double tamanho = bytes.toDouble();

    int indice = 0;

    while (tamanho >= 1024 &&
        indice < unidades.length - 1) {
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
