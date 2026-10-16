import 'package:flutter/material.dart';

import '../models/estatisticas_obra.dart';
import '../services/estatisticas_obras_service.dart';
import 'estatisticas_obra_page.dart';

class EstatisticasAutorPage extends StatefulWidget {
  const EstatisticasAutorPage({super.key});

  @override
  State<EstatisticasAutorPage> createState() =>
      _EstatisticasAutorPageState();
}

class _EstatisticasAutorPageState
    extends State<EstatisticasAutorPage> {
  final EstatisticasObrasService _service =
  EstatisticasObrasService();

  late Future<List<EstatisticasObra>> _futureEstatisticas;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  void _carregarEstatisticas() {
    _futureEstatisticas = _service.obterEstatisticasAutor();
  }

  Future<void> _atualizar() async {
    setState(_carregarEstatisticas);

    try {
      await _futureEstatisticas;
    } catch (_) {
      // O FutureBuilder apresenta o erro na interface.
    }
  }

  int _somarVisualizacoes(List<EstatisticasObra> obras) {
    return obras.fold(
      0,
          (total, obra) => total + obra.visualizacoes,
    );
  }

  int _somarCliques(List<EstatisticasObra> obras) {
    return obras.fold(
      0,
          (total, obra) => total + obra.cliquesPdf,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas das minhas obras'),
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
      body: FutureBuilder<List<EstatisticasObra>>(
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

          final obras = snapshot.data ?? [];

          if (obras.isEmpty) {
            return RefreshIndicator(
              onRefresh: _atualizar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 100),
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Ainda não existem obras para apresentar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quando publicares obras, poderás acompanhar '
                        'as respetivas estatísticas nesta página.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final totalVisualizacoes = _somarVisualizacoes(obras);
          final totalCliques = _somarCliques(obras);

          return RefreshIndicator(
            onRefresh: _atualizar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Desempenho das publicações',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Consulta a atividade registada nas tuas obras.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),

                // RESUMO GERAL
                LayoutBuilder(
                  builder: (context, constraints) {
                    final largura = constraints.maxWidth;

                    final colunas = largura >= 700
                        ? 3
                        : 1;

                    final proporcao = colunas == 3 ? 1.45 : 2.2;

                    return GridView.count(
                      crossAxisCount: colunas,
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: proporcao,
                      children: [
                        _cartaoResumo(
                          titulo: 'Obras',
                          valor: obras.length,
                          icone: Icons.menu_book_outlined,
                        ),
                        _cartaoResumo(
                          titulo: 'Visualizações',
                          valor: totalVisualizacoes,
                          icone: Icons.visibility_outlined,
                        ),
                        _cartaoResumo(
                          titulo: 'Cliques no PDF',
                          valor: totalCliques,
                          icone: Icons.picture_as_pdf_outlined,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  'Desempenho por obra',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                ...obras.map(_cartaoObra),

                const SizedBox(height: 20),

                const Text(
                  'As estatísticas refletem os eventos efetivamente '
                      'registados no Supabase.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cartaoResumo({
    required String titulo,
    required int valor,
    required IconData icone,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 28,
              color: const Color(0xFF245A8D),
            ),
            const SizedBox(height: 8),
            Text(
              valor.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoObra(EstatisticasObra obra) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EstatisticasObraPage(
                obraId: obra.obraId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    color: Color(0xFF245A8D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      obra.titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  _indicadorObra(
                    icone: Icons.visibility_outlined,
                    titulo: 'Visualizações',
                    valor: obra.visualizacoes,
                  ),
                  _indicadorObra(
                    icone: Icons.picture_as_pdf_outlined,
                    titulo: 'Cliques no PDF',
                    valor: obra.cliquesPdf,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicadorObra({
    required IconData icone,
    required String titulo,
    required int valor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icone,
          size: 18,
          color: Colors.black54,
        ),
        const SizedBox(width: 6),
        Text(
          '$titulo: $valor',
          style: const TextStyle(fontSize: 13),
        ),
      ],
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

