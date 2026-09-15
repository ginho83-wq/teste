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
      color: const Color(0xfff0f2f5),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 14 : 18,
            vertical: 14,
          ),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xffdfe2e6),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÍTULO
              Text(
                obra.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              // AUTOR
              if (obra.autor.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  obra.autor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.black54,
                  ),
                ),
              ],

              // CATEGORIA E ANO
              if (obra.categoria.isNotEmpty ||
                  obra.anoObra != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    if (obra.categoria.isNotEmpty)
                      _Etiqueta(
                        texto: obra.categoria,
                      ),

                    if (obra.anoObra != null)
                      _Etiqueta(
                        texto: obra.anoObra.toString(),
                      ),
                  ],
                ),
              ],

              // DESCRIÇÃO
              if ((obra.descricao ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  obra.descricao!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.black54,
                  ),
                ),
              ],

              const SizedBox(height: 9),

              // AÇÃO
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 15,
                    color: Colors.black54,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Ver publicação',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;

  const _Etiqueta({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xffdfe2e6),
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11.5,
          color: Colors.black54,
        ),
      ),
    );
  }
}

