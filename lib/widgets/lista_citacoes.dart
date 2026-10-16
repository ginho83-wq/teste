import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/citacao_obra.dart';
import '../services/citacoes_obras_service.dart';

class ListaCitacoes extends StatefulWidget {
  final String obraId;

  const ListaCitacoes({
    super.key,
    required this.obraId,
  });

  @override
  State<ListaCitacoes> createState() => _ListaCitacoesState();
}

class _ListaCitacoesState extends State<ListaCitacoes> {
  final CitacoesObrasService _service =
      CitacoesObrasService.instance;

  late Future<List<CitacaoObra>> _futureCitacoes;

  @override
  void initState() {
    super.initState();
    _carregarCitacoes();
  }

  @override
  void didUpdateWidget(covariant ListaCitacoes oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.obraId != widget.obraId) {
      _carregarCitacoes();
    }
  }

  void _carregarCitacoes() {
    _futureCitacoes = _service.obterCitacoes(widget.obraId);
  }

  Future<void> _atualizar() async {
    setState(_carregarCitacoes);

    try {
      await _futureCitacoes;
    } catch (_) {
      // O FutureBuilder apresenta o erro.
    }
  }

  Future<void> _copiarCitacao(String texto) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: texto),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referência bibliográfica copiada.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível copiar a referência.',
          ),
        ),
      );
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Data não disponível';
    }

    final dataLocal = data.toLocal();

    final dia = dataLocal.day.toString().padLeft(2, '0');
    final mes = dataLocal.month.toString().padLeft(2, '0');
    final ano = dataLocal.year.toString();

    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CitacaoObra>>(
      future: _futureCitacoes,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 36,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Não foi possível carregar as citações.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _atualizar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final List<CitacaoObra> citacoes =
            snapshot.data ?? <CitacaoObra>[];

        if (citacoes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 42,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ainda não existem referências registadas.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'As referências bibliográficas registadas para esta obra aparecerão aqui.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _atualizar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${citacoes.length} ${citacoes.length == 1 ? 'referência registada' : 'referências registadas'}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _atualizar,
                  tooltip: 'Atualizar lista',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...citacoes.map(
                  (citacao) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              citacao.tipoCitacao
                                  ?.trim()
                                  .isNotEmpty ==
                                  true
                                  ? citacao.tipoCitacao!
                                  : 'Referência bibliográfica',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        citacao.textoCitacao,
                        style: const TextStyle(height: 1.6),
                      ),
                      if (citacao.urlCitacao
                          ?.trim()
                          .isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 10),
                        SelectableText(
                          citacao.urlCitacao!,
                          style: const TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatarData(
                                citacao.dataCriacao,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copiarCitacao(
                              citacao.textoCitacao,
                            ),
                            tooltip: 'Copiar referência',
                            icon: const Icon(Icons.copy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

