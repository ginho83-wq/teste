import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../widgets/barra_pesquisa.dart';
import '../widgets/obra_lista_item.dart';
import '../widgets/paginacao.dart';

class AcervoPesquisaResultadosPage extends StatefulWidget {
  final String query;

  const AcervoPesquisaResultadosPage({
    super.key,
    required this.query,
  });

  @override
  State<AcervoPesquisaResultadosPage> createState() =>
      _AcervoPesquisaResultadosPageState();
}

class _AcervoPesquisaResultadosPageState
    extends State<AcervoPesquisaResultadosPage> {
  final ObrasRepository _repository = ObrasRepository.instancia;

  final TextEditingController _pesquisaController =
  TextEditingController();

  static const int _obrasPorPagina = 10;

  List<Obra> _obras = [];

  bool _carregando = true;

  String _erro = '';

  int _paginaAtual = 1;

  String get _queryAtual =>
      Uri.decodeComponent(widget.query).trim();

  int get _totalPaginas {
    if (_obras.isEmpty) {
      return 0;
    }

    return (_obras.length / _obrasPorPagina).ceil();
  }

  List<Obra> get _obrasPaginaAtual {
    if (_obras.isEmpty) {
      return [];
    }

    final inicio =
        (_paginaAtual - 1) * _obrasPorPagina;

    if (inicio >= _obras.length) {
      return [];
    }

    final fim = (inicio + _obrasPorPagina).clamp(
      0,
      _obras.length,
    );

    return _obras.sublist(
      inicio,
      fim,
    );
  }

  @override
  void initState() {
    super.initState();

    _pesquisaController.text = _queryAtual;

    _carregarResultados();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();

    super.dispose();
  }

  // =========================================================
  // CARREGAR RESULTADOS
  // =========================================================

  Future<void> _carregarResultados() async {
    final termo = _queryAtual;

    if (termo.isEmpty) {
      if (!mounted) return;

      setState(() {
        _obras = [];
        _paginaAtual = 1;
        _carregando = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = '';
        _paginaAtual = 1;
      });
    }

    try {
      final resultado =
      await _repository.pesquisar(termo);

      if (!mounted) return;

      setState(() {
        _obras = resultado;
        _paginaAtual = 1;
        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO PESQUISA: erro ao carregar resultados: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];
        _erro =
        'Não foi possível realizar a pesquisa.';
        _paginaAtual = 1;
        _carregando = false;
      });
    }
  }

  // =========================================================
  // PAGINAÇÃO
  // =========================================================

  void _mudarPagina(int pagina) {
    if (pagina < 1 || pagina > _totalPaginas) {
      return;
    }

    setState(() {
      _paginaAtual = pagina;
    });
  }

  // =========================================================
  // NOVA PESQUISA
  // =========================================================

  void _executarPesquisa() {
    final texto =
    _pesquisaController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    context.go(
      '/acervo/pesquisa/${Uri.encodeComponent(texto)}',
    );
  }

  // =========================================================
  // LIMPAR PESQUISA
  // =========================================================

  void _limparPesquisa() {
    _pesquisaController.clear();

    if (!mounted) return;

    context.go('/acervo');
  }

  // =========================================================
  // ABRIR OBRA
  // =========================================================

  void _abrirObra(Obra obra) {
    if (!mounted) return;

    context.go('/obra/${obra.id}');
  }

  // =========================================================
  // CAMPO DE PESQUISA
  // =========================================================

  Widget _campoPesquisa() {
    return BarraPesquisa(
      controller: _pesquisaController,
      hintText: 'Pesquisar obras académicas',
      onPesquisar: _executarPesquisa,
      onLimpar: _limparPesquisa,
    );
  }

  // =========================================================
  // CABEÇALHO
  // =========================================================

  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acervo',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Resultados para "$_queryAtual"',
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '${_obras.length} publicação(ões) encontrada(s)',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CONTEÚDO
  // =========================================================

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erro.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            _erro,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_obras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 70,
            horizontal: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 50,
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 16),

              const Text(
                'Nenhuma publicação encontrada.',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Tente pesquisar por outro título, '
                    'autor ou categoria.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton(
                onPressed: () {
                  context.go('/acervo');
                },
                child: const Text(
                  'Voltar ao Acervo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          itemCount: _obrasPaginaAtual.length,
          itemBuilder: (context, index) {
            final obra =
            _obrasPaginaAtual[index];

            return ObraListaItem(
              obra: obra,
              onTap: () => _abrirObra(obra),
              mobile:
              MediaQuery.of(context).size.width < 600,
            );
          },
        ),

        Paginacao(
          paginaAtual: _paginaAtual,
          totalPaginas: _totalPaginas,
          onPaginaChanged: _mudarPagina,
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Acervo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final larguraMaxima =
          constraints.maxWidth > 1100
              ? 1000.0
              : constraints.maxWidth * 0.92;

          return Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: SizedBox(
                width: larguraMaxima,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _campoPesquisa(),

                    const SizedBox(height: 32),

                    _cabecalho(),

                    const SizedBox(height: 24),

                    _conteudo(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

