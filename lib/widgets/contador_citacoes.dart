import 'package:flutter/material.dart';

import '../services/citacoes_obras_service.dart';

class ContadorCitacoes extends StatefulWidget {
  final String obraId;

  const ContadorCitacoes({
    super.key,
    required this.obraId,
  });

  @override
  State<ContadorCitacoes> createState() =>
      _ContadorCitacoesState();
}

class _ContadorCitacoesState extends State<ContadorCitacoes> {
  final CitacoesObrasService _service =
      CitacoesObrasService.instance;

  late Future<int> _futureContagem;

  @override
  void initState() {
    super.initState();
    _carregarContagem();
  }

  @override
  void didUpdateWidget(covariant ContadorCitacoes oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.obraId != widget.obraId) {
      _carregarContagem();
    }
  }

  void _carregarContagem() {
    _futureContagem = _service.contarCitacoes(widget.obraId);
  }

  Future<void> _atualizar() async {
    setState(_carregarContagem);

    try {
      await _futureContagem;
    } catch (_) {
      // O FutureBuilder apresenta o erro.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<int>(
          future: _futureContagem,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('A consultar citações...'),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Não foi possível carregar o contador.',
                    ),
                  ),
                  IconButton(
                    onPressed: _atualizar,
                    tooltip: 'Tentar novamente',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              );
            }

            final int total = snapshot.data ?? 0;

            return Row(
              children: [
                const Icon(
                  Icons.format_quote,
                  size: 30,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$total ${total == 1 ? 'referência registada' : 'referências registadas'}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Referências bibliográficas registadas nesta plataforma.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _atualizar,
                  tooltip: 'Atualizar contador',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

