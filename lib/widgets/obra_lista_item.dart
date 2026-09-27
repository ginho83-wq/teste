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
    final List<String> informacoes = [];

    // AUTOR
    if (obra.autor.trim().isNotEmpty) {
      informacoes.add(obra.autor.trim());
    }

    // ANO DA OBRA — ENTRE PARÊNTESES
    if (obra.anoObra != null) {
      informacoes.add(
        '(${obra.anoObra})',
      );
    }

    // DESCRIÇÃO
    if ((obra.descricao ?? '').trim().isNotEmpty) {
      informacoes.add(
        obra.descricao!.trim(),
      );
    }

    // CATEGORIA
    if (obra.categoria.trim().isNotEmpty) {
      informacoes.add(
        obra.categoria.trim(),
      );
    }

    // ANO DE PUBLICAÇÃO
    informacoes.add(
      'Publicada em ${obra.dataPublicacao.year}',
    );

    // FORMATO
    informacoes.add('PDF');

    // TAMANHO DO ARQUIVO
    if (obra.tamanhoArquivoBytes != null &&
        obra.tamanhoArquivoBytes! > 0) {
      informacoes.add(
        _formatarTamanho(
          obra.tamanhoArquivoBytes!,
        ),
      );
    }

    final String segundaLinha = informacoes.join(', ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xfff8f9fa),
        splashColor: const Color(0xfff1f3f4),
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 8 : 12,
            vertical: 18,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xffdadce0),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRIMEIRA LINHA — TÍTULO
                    Text(
                      obra.titulo,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1a73e8),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xff1a73e8),
                        decorationThickness: 1.2,
                      ),
                    ),

                    // LINHA SEGUINTE — INFORMAÇÕES
                    if (segundaLinha.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                        ),
                        child: Text(
                          segundaLinha,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xff5f6368),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // SETA À DIREITA
              const Icon(
                Icons.arrow_forward,
                size: 20,
                color: Color(0xff5f6368),
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

