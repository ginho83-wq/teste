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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 14 : 18,
            vertical: 18,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xffdfe2e6),
                width: 1,
              ),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // AUTOR
              if (obra.autor.isNotEmpty)
                _Texto(
                  texto: obra.autor,
                  destaque: true,
                ),

              // ANO DA OBRA
              if (obra.anoObra != null)
                _Texto(
                  texto: '(${obra.anoObra})',
                ),

              // TÍTULO
              _Texto(
                texto: obra.titulo,
                titulo: true,
              ),

              // DESCRIÇÃO / RESUMO
              if ((obra.descricao ?? '').isNotEmpty)
                _Texto(
                  texto: obra.descricao!,
                ),

              // CATEGORIA
              if (obra.categoria.isNotEmpty)
                _Texto(
                  texto: obra.categoria,
                ),

              // DATA DE PUBLICAÇÃO
              if (obra.dataPublicacao != null)
                _Texto(
                  texto:
                  'Publicada em ${_formatarData(obra.dataPublicacao!)}',
                ),

              // NÚMERO DE PÁGINAS — OPCIONAL
              if (obra.numeroPaginas != null &&
                  obra.numeroPaginas! > 0)
                _Texto(
                  texto: '${obra.numeroPaginas} páginas',
                ),

              // FORMATO DO DOCUMENTO
              _Texto(
                texto: 'PDF',
              ),

              // TAMANHO DO ARQUIVO — OPCIONAL
              if (obra.tamanhoArquivoBytes != null &&
                  obra.tamanhoArquivoBytes! > 0)
                _Texto(
                  texto: _formatarTamanho(
                    obra.tamanhoArquivoBytes!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  String _formatarTamanho(int bytes) {
    const unidades = [
      'B',
      'KB',
      'MB',
      'GB',
      'TB',
    ];

    double tamanho = bytes.toDouble();
    int indice = 0;

    while (tamanho >= 1024 && indice < unidades.length - 1) {
      tamanho /= 1024;
      indice++;
    }

    if (indice == 0) {
      return '${tamanho.toStringAsFixed(0)} ${unidades[indice]}';
    }

    return '${tamanho.toStringAsFixed(1)} ${unidades[indice]}';
  }
}

class _Texto extends StatelessWidget {
  final String texto;
  final bool destaque;
  final bool titulo;

  const _Texto({
    required this.texto,
    this.destaque = false,
    this.titulo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      maxLines: titulo ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: titulo ? 15 : 12.5,
        height: titulo ? 1.3 : 1.35,
        fontWeight: titulo || destaque
            ? FontWeight.w600
            : FontWeight.w400,
        color: titulo
            ? Colors.black87
            : destaque
            ? Colors.black87
            : Colors.black54,
      ),
    );
  }
}

