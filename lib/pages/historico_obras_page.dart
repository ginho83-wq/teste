import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../services/historico_obras_service.dart';

class HistoricoObrasPage extends StatefulWidget {
  const HistoricoObrasPage({super.key});

  @override
  State<HistoricoObrasPage> createState() => _HistoricoObrasPageState();
}

class _HistoricoObrasPageState extends State<HistoricoObrasPage> {
  final HistoricoObrasService _service = HistoricoObrasService();

  List<HistoricoObra> _historico = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final historico = await _service.obterHistorico();

      if (!mounted) return;

      setState(() {
        _historico = historico;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar o histórico.';
        _carregando = false;
      });
    }
  }

  Future<void> _removerConsulta(HistoricoObra obra) async {
    try {
      await _service.removerConsulta(id: obra.id);

      if (!mounted) return;

      setState(() {
        _historico.removeWhere((item) => item.id == obra.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consulta removida do histórico.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível remover a consulta.'),
        ),
      );
    }
  }

  Future<void> _limparHistorico() async {
    if (_historico.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Limpar histórico'),
          content: const Text(
            'Tem a certeza de que deseja remover todo o histórico de obras consultadas?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _service.limparHistorico();

      if (!mounted) return;

      setState(() {
        _historico.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Histórico limpo com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível limpar o histórico.'),
        ),
      );
    }
  }

  Future<void> _abrirDocumento(HistoricoObra obra) async {
    final url = obra.urlDocumento;

    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento não disponível.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endereço do documento inválido.'),
        ),
      );
      return;
    }

    final abriu = await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
    );

    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o documento.'),
        ),
      );
    }
  }

  String _formatarData(DateTime data) {
    final local = data.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();

    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de obras'),
        actions: [
          if (!_carregando && _historico.isNotEmpty)
            TextButton(
              onPressed: _limparHistorico,
              child: const Text('Limpar histórico'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1080,
          ),
          child: _buildConteudo(),
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _carregarHistorico,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historico.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'O seu histórico está vazio.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'As obras que consultar aparecerão aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
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
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          40,
        ),
        itemCount: _historico.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final obra = _historico[index];

          return _HistoricoObraCard(
            obra: obra,
            dataFormatada: _formatarData(obra.dataConsulta),
            onAbrir: () => _abrirDocumento(obra),
            onRemover: () => _removerConsulta(obra),
          );
        },
      ),
    );
  }
}

class _HistoricoObraCard extends StatelessWidget {
  final HistoricoObra obra;
  final String dataFormatada;
  final VoidCallback onAbrir;
  final VoidCallback onRemover;

  const _HistoricoObraCard({
    required this.obra,
    required this.dataFormatada,
    required this.onAbrir,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    obra.titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover do histórico',
                  onPressed: onRemover,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (obra.autor != null &&
                obra.autor!.trim().isNotEmpty)
              Text(
                obra.autor!,
                style: tema.textTheme.bodyMedium,
              ),
            if (obra.categoria != null &&
                obra.categoria!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                obra.categoria!,
                style: tema.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Consultado em $dataFormatada',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onAbrir,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir documento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

