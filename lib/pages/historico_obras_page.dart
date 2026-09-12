import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../services/historico_obras_service.dart';

class HistoricoObrasPage extends StatefulWidget {
  const HistoricoObrasPage({super.key});

  @override
  State<HistoricoObrasPage> createState() =>
      _HistoricoObrasPageState();
}

class _HistoricoObrasPageState
    extends State<HistoricoObrasPage> {
  final HistoricoObrasService _service =
  HistoricoObrasService();

  List<HistoricoObra> _historico = [];

  bool _carregando = true;
  bool _limpando = false;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
    });

    try {
      final historico =
      await _service.obterHistorico();

      if (!mounted) return;

      setState(() {
        _historico = historico;
        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'Erro ao carregar histórico: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar o histórico.',
          ),
        ),
      );
    }
  }

  Future<void> _removerConsulta(
      HistoricoObra obra,
      ) async {
    try {
      await _service.removerConsulta(
        id: obra.id,
      );

      if (!mounted) return;

      setState(() {
        _historico.removeWhere(
              (item) => item.id == obra.id,
        );
      });
    } catch (e) {
      debugPrint(
        'Erro ao remover consulta: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível remover esta consulta.',
          ),
        ),
      );
    }
  }

  Future<void> _limparHistorico() async {
    if (_historico.isEmpty || _limpando) {
      return;
    }

    final confirmar =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Limpar histórico',
          ),
          content: const Text(
            'Tem certeza que deseja limpar todo o histórico de obras consultadas?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _limpando = true;
    });

    try {
      await _service.limparHistorico();

      if (!mounted) return;

      setState(() {
        _historico.clear();
        _limpando = false;
      });
    } catch (e) {
      debugPrint(
        'Erro ao limpar histórico: $e',
      );

      if (!mounted) return;

      setState(() {
        _limpando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível limpar o histórico.',
          ),
        ),
      );
    }
  }

  Future<void> _abrirDocumento(
      HistoricoObra obra,
      ) async {
    final url = obra.urlDocumento?.trim();

    if (url == null || url.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta obra não possui documento disponível.',
          ),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      return;
    }

    try {
      await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );
    } catch (e) {
      debugPrint(
        'Erro ao abrir documento: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Obras consultadas',
        ),
        actions: [
          if (_historico.isNotEmpty)
            TextButton.icon(
              onPressed:
              _limpando ? null : _limparHistorico,
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'Limpar',
              ),
            ),
        ],
      ),
      body: _construirConteudo(),
    );
  }

  Widget _construirConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_historico.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 56,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma obra consultada recentemente.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'As obras que você consultar aparecerão aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarHistorico,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _historico.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final obra = _historico[index];

          return _buildHistoricoCard(obra);
        },
      ),
    );
  }

  Widget _buildHistoricoCard(
      HistoricoObra obra,
      ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_outlined,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    obra.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                  if (obra.autor != null &&
                      obra.autor!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      obra.autor!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],

                  if (obra.categoria != null &&
                      obra.categoria!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      obra.categoria!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            _abrirDocumento(obra),
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 17,
                        ),
                        label: const Text(
                          'Abrir',
                        ),
                      ),

                      IconButton(
                        tooltip:
                        'Remover do histórico',
                        onPressed: () =>
                            _removerConsulta(obra),
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
