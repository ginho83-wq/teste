import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/historico_obra.dart';
import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/historico_obras_service.dart';
import '../widgets/barra_pesquisa.dart';
import '../widgets/historico_lista_item.dart';
import '../widgets/obra_lista_item.dart';

class AcervoResultadosPage extends StatefulWidget {
  final String? query;
  final String? categoria;
  final String? obraId;

  const AcervoResultadosPage({
    super.key,
    this.query,
    this.categoria,
    this.obraId,
  });

  @override
  State<AcervoResultadosPage> createState() =>
      _AcervoResultadosPageState();
}

class _AcervoResultadosPageState
    extends State<AcervoResultadosPage> {
  final ObrasRepository _repository =
      ObrasRepository.instancia;

  final HistoricoObrasService _historicoService =
      HistoricoObrasService.instancia;

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obras = [];
  List<HistoricoObra> _historico = [];

  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();

    _pesquisaController.text = widget.query ?? '';

    _carregar();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      List<Obra> obras;

      // 1. Abrir uma obra específica
      if (widget.obraId != null &&
          widget.obraId!.trim().isNotEmpty) {
        final obra = await _repository.carregarPorId(
          widget.obraId!.trim(),
        );

        obras = obra == null ? [] : [obra];
      }

      // 2. Filtrar por categoria
      else if (widget.categoria != null &&
          widget.categoria!.trim().isNotEmpty) {
        obras = await _repository.carregarPorCategoria(
          widget.categoria!.trim(),
        );
      }

      // 3. Pesquisar por texto
      else if (widget.query != null &&
          widget.query!.trim().isNotEmpty) {
        obras = await _repository.pesquisar(
          widget.query!.trim(),
        );
      }

      // 4. Mostrar todo o acervo
      else {
        obras = await _repository.carregarObras(
          pagina: 1,
          limite: 50,
        );
      }

      if (!mounted) return;

      setState(() {
        _obras = obras;
        _carregando = false;
      });

      await _carregarHistorico();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar o acervo.';
        _carregando = false;
      });

      debugPrint(
        'ACERVO: erro ao carregar obras: $e',
      );
    }
  }

  Future<void> _carregarHistorico() async {
    try {
      final historico =
      await _historicoService.obterConsultasRecentes(
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _historico = historico;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao carregar histórico: $e',
      );
    }
  }

  void _abrirDetalhes(Obra obra) {
    if (!mounted) return;

    context.go('/obra/${obra.id}');
  }

  void _abrirHistorico(HistoricoObra item) {
    context.go('/obra/${item.obraId}');
  }

  void _pesquisar() {
    final pesquisa =
    _pesquisaController.text.trim();

    if (pesquisa.isEmpty) {
      context.go('/acervo');
      return;
    }

    context.go(
      '/acervo/pesquisa/${Uri.encodeComponent(pesquisa)}',
    );
  }

  void _limparPesquisa() {
    _pesquisaController.clear();

    context.go('/acervo');
  }

  void _abrirCategoria(String categoria) {
    context.go(
      '/categoria/${Uri.encodeComponent(categoria)}',
    );
  }

  Future<void> _removerHistorico(
      HistoricoObra item,
      ) async {
    /*
     * A implementação concreta da remoção do histórico
     * depende dos métodos existentes no
     * HistoricoObrasService.
     *
     * Por enquanto removemos o item apenas da lista
     * apresentada nesta página.
     */
    if (!mounted) return;

    setState(() {
      _historico.removeWhere(
            (historico) =>
        historico.obraId == item.obraId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acervo'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          BarraPesquisa(
            controller: _pesquisaController,
            hintText: 'Pesquisar no acervo...',
            onPesquisar: _pesquisar,
            onLimpar: _limparPesquisa,
          ),
          Expanded(
            child: _buildConteudo(),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregar,
                child: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_obras.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhuma obra encontrada.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _buildDesktop();
        }

        return _buildMobile();
      },
    );
  }

  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildListaObras(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildHistorico(),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildListaObras(),
          const SizedBox(height: 24),
          _buildHistorico(),
        ],
      ),
    );
  }

  Widget _buildListaObras() {
    return ListView.separated(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _obras.length,
      separatorBuilder: (_, __) =>
      const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final obra = _obras[index];

        return ObraListaItem(
          obra: obra,
          onTap: () => _abrirDetalhes(obra),
        );
      },
    );
  }

  Widget _buildHistorico() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Obras consultadas recentemente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/historico');
                    },
                    child: const Text('Ver tudo'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_historico.isEmpty)
                const Padding(
                  padding:
                  EdgeInsets.symmetric(
                    vertical: 20,
                  ),
                  child: Text(
                    'Ainda não existem consultas recentes.',
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount: _historico.length,
                  separatorBuilder: (_, __) =>
                  const Divider(),
                  itemBuilder:
                      (context, index) {
                    final item =
                    _historico[index];

                    return HistoricoListaItem(
                      obra: item,
                      onAbrir: () {
                        _abrirHistorico(item);
                      },
                      onRemover: () {
                        _removerHistorico(item);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
