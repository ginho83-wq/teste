import 'package:flutter/material.dart';

import '../models/estatisticas_obra.dart';
import '../services/estatisticas_obras_service.dart';

class EstatisticasObraPage extends StatefulWidget {
  final String obraId;

  const EstatisticasObraPage({
    super.key,
    required this.obraId,
  });

  @override
  State<EstatisticasObraPage> createState() =>
      _EstatisticasObraPageState();
}

class _EstatisticasObraPageState
    extends State<EstatisticasObraPage> {
  final EstatisticasObrasService _service =
  EstatisticasObrasService();

  late Future<EstatisticasObra> _futureEstatisticas;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  void _carregarEstatisticas() {
    _futureEstatisticas =
        _service.obterEstatisticasObra(widget.obraId);
  }

  Future<void> _atualizar() async {
    setState(_carregarEstatisticas);

    try {
      await _futureEstatisticas;
    } catch (_) {
      // O FutureBuilder apresenta o erro na interface.
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return 'Sem eventos registados';
    }

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
        title: const Text('Estatísticas da obra'),
        backgroundColor: const Color(0xFFEAF4FF),
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Atualizar estatísticas',
            onPressed: _atualizar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<EstatisticasObra>(
        future: _futureEstatisticas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _mensagemErro(
              'Não foi possível carregar as estatísticas.',
              snapshot.error,
            );
          }

          final estatisticas = snapshot.data;

          if (estatisticas == null) {
            return const Center(
              child: Text('Não existem dados disponíveis.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _atualizar,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  estatisticas.titulo,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acompanhamento das consultas e dos acessos ao PDF.',
                ),
                const SizedBox(height: 24),

                _cartaoEstatistica(
                  contexto: context,
                  titulo: 'Visualizações',
                  valor: estatisticas.visualizacoes,
                  descricao: 'Eventos de consulta da obra',
                  icone: Icons.visibility_outlined,
                ),

                const SizedBox(height: 16),

                _cartaoEstatistica(
                  contexto: context,
                  titulo: 'Cliques no PDF',
                  valor: estatisticas.cliquesPdf,
                  descricao: 'Ações para abrir o documento',
                  icone: Icons.picture_as_pdf_outlined,
                ),

                const SizedBox(height: 16),

                _cartaoEstatistica(
                  contexto: context,
                  titulo: 'Total de eventos',
                  valor: estatisticas.totalEventos,
                  descricao: 'Visualizações e cliques somados',
                  icone: Icons.analytics_outlined,
                ),

                const SizedBox(height: 24),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Último evento'),
                    subtitle: Text(
                      _formatarData(estatisticas.ultimoEvento),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Nota: os valores correspondem aos eventos '
                      'efetivamente registados no sistema.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cartaoEstatistica({
    required BuildContext contexto,
    required String titulo,
    required int valor,
    required String descricao,
    required IconData icone,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icone,
                color: const Color(0xFF245A8D),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descricao,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valor.toString(),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mensagemErro(String mensagem, Object? erro) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              erro?.toString() ?? 'Erro desconhecido.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _atualizar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

