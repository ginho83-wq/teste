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
    // 2ª LINHA — AUTOR + ANO DA OBRA + DESCRIÇÃO
    final List<String> segundaLinha = [];

    if (obra.autor.trim().isNotEmpty) {
      segundaLinha.add(obra.autor.trim());
    }

    if (obra.anoObra != null) {
      segundaLinha.add('(${obra.anoObra})');
    }

    if ((obra.descricao ?? '').trim().isNotEmpty) {
      segundaLinha.add(obra.descricao!.trim());
    }

    // 3ª LINHA — CATEGORIA + DATA + PDF + TAMANHO
    final List<String> terceiraLinha = [];

    if (obra.categoria.trim().isNotEmpty) {
      terceiraLinha.add(obra.categoria.trim());
    }

    terceiraLinha.add(
      'Publicada em ${obra.dataPublicacao.year}',
    );

    terceiraLinha.add('PDF');

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

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xfff8f9fa),
        splashColor: const Color(0xfff1f3f4),
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 8 : 12,
            vertical: 17,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // 1ª LINHA — TÍTULO
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      obra.titulo,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1a73e8),
                        decoration:
                        TextDecoration.underline,
                        decorationColor:
                        Color(0xff1a73e8),
                        decorationThickness: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.arrow_forward,
                    size: 19,
                    color: Color(0xff6b7280),
                  ),
                ],
              ),

              // ESPAÇAMENTO ENTRE A 1ª E A 2ª LINHA
              const SizedBox(height: 4),

              // 2ª LINHA — AUTOR + ANO + DESCRIÇÃO
              if (textoSegundaLinha.isNotEmpty)
                Text(
                  textoSegundaLinha,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff5f6368),
                  ),
                ),

              // ESPAÇAMENTO ENTRE A 2ª E A 3ª LINHA
              const SizedBox(height: 4),

              // 3ª LINHA — CATEGORIA + DATA + PDF + TAMANHO
              if (textoTerceiraLinha.isNotEmpty)
                Text(
                  textoTerceiraLinha,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff5f6368),
                  ),
                ),

              // ESPAÇAMENTO ANTES DA LINHA
              const SizedBox(height: 16),

              // LINHA DIVISÓRIA:
              // 1 PX, SEM SOMBRA, SEM EFEITO.
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xffe1e4e8),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      return '${tamanho.toStringAsFixed(0)} ${unidades[indice]}';
    }

    return '${tamanho.toStringAsFixed(1)} ${unidades[indice]}';
  }
}
