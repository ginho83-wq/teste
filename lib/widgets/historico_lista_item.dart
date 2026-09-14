import 'package:flutter/material.dart';

import '../models/historico_obra.dart';

class HistoricoListaItem extends StatelessWidget {
  final HistoricoObra obra;
  final VoidCallback onAbrir;
  final VoidCallback onRemover;

  const HistoricoListaItem({
    super.key,
    required this.obra,
    required this.onAbrir,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onAbrir,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: const Color(0xffe0e3e7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xffeef4fb),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.history,
                  size: 20,
                  color: Color(0xff1565C0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obra.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (obra.autor != null &&
                        obra.autor!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        obra.autor!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    if (obra.categoria != null &&
                        obra.categoria!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        obra.categoria!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Remover do histórico',
                onPressed: onRemover,
                icon: const Icon(
                  Icons.close,
                  size: 19,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
