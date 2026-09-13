import 'package:flutter/material.dart';

import '../models/obra.dart';

/// Abre o diálogo reutilizável de detalhes de uma obra.
///
/// Este widget não acessa Supabase nem repositories.
/// Toda a lógica fica no chamador através dos callbacks.
Future<void> mostrarDetalhesObraDialog(
    BuildContext context, {
      required Obra obra,
      bool mostrarSolicitarRemocao = false,
      bool mostrarAbrir = true,
      String? statusRemocao,
      VoidCallback? onSolicitarRemocao,
      VoidCallback? onAbrir,
    }) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 560,
            maxHeight: 650,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              18,
              24,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------------------
                // CABEÇALHO
                // ----------------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        obra.titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------------------
                // INFORMAÇÕES DA OBRA
                // ----------------------------------------------------------
                _InformacaoObra(
                  titulo: 'Autor',
                  valor: obra.autor,
                ),

                const SizedBox(height: 14),

                _InformacaoObra(
                  titulo: 'Ano da obra',
                  valor: _formatarAno(obra.anoObra),
                ),

                const SizedBox(height: 14),

                _InformacaoObra(
                  titulo: 'Data de publicação',
                  valor: _formatarData(obra.dataPublicacao),
                ),

                const SizedBox(height: 14),

                _InformacaoObra(
                  titulo: 'Categoria',
                  valor: obra.categoria,
                ),

                // ----------------------------------------------------------
                // STATUS DA REMOÇÃO
                // ----------------------------------------------------------
                if (statusRemocao != null) ...[
                  const SizedBox(height: 20),
                  _StatusRemocao(
                    status: statusRemocao,
                  ),
                ],

                // ----------------------------------------------------------
                // SOLICITAR REMOÇÃO
                // ----------------------------------------------------------
                if (mostrarSolicitarRemocao &&
                    onSolicitarRemocao != null) ...[
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onSolicitarRemocao();
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 19,
                      ),
                      label: const Text(
                        'Solicitar remoção',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(
                          color: Colors.red.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ----------------------------------------------------------
                // AÇÕES
                // ----------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Cancelar'),
                    ),

                    if (mostrarAbrir && onAbrir != null) ...[
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onAbrir();
                        },
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 18,
                        ),
                        label: const Text('Abrir'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================================
// COMPONENTES AUXILIARES
// ============================================================================

class _InformacaoObra extends StatelessWidget {
  final String titulo;
  final String? valor;

  const _InformacaoObra({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final texto = valor == null || valor!.trim().isEmpty
        ? '—'
        : valor!.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          texto,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _StatusRemocao extends StatelessWidget {
  final String status;

  const _StatusRemocao({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late String texto;
    late IconData icone;
    late Color cor;

    switch (status) {
      case 'pendente':
        texto = 'Remoção em análise';
        icone = Icons.hourglass_empty;
        cor = Colors.orange.shade700;
        break;

      case 'aprovada':
        texto = 'Remoção aprovada';
        icone = Icons.check_circle_outline;
        cor = Colors.green.shade700;
        break;

      case 'rejeitada':
        texto = 'Pedido de remoção rejeitado';
        icone = Icons.info_outline;
        cor = Colors.red.shade700;
        break;

      default:
        texto = status;
        icone = Icons.info_outline;
        cor = Colors.black54;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.06),
        border: Border.all(
          color: cor.withOpacity(0.25),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            size: 19,
            color: cor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORMATAÇÃO
// ============================================================================

String _formatarAno(dynamic ano) {
  if (ano == null) {
    return '—';
  }

  final valor = ano.toString().trim();

  if (valor.isEmpty || valor == 'null') {
    return '—';
  }

  return valor;
}

String _formatarData(DateTime? data) {
  if (data == null) {
    return '—';
  }

  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final ano = data.year.toString();

  return '$dia/$mes/$ano';
}
