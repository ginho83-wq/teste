import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../widgets/obra_lista_item.dart';
import '../widgets/detalhes_obra_dialog.dart';
import '../widgets/paginacao.dart';

class CategoriaResultadosPage extends StatefulWidget {
  final String categoria;

  const CategoriaResultadosPage({
    super.key,
    required this.categoria,
  });

  @override
  State<CategoriaResultadosPage> createState() =>
      _CategoriaResultadosPageState();
}

class _CategoriaResultadosPageState
    extends State<CategoriaResultadosPage> {
  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  static const int _itensPorPagina = 10;

  List<Obra> _obras = [];

  bool _carregando = true;
  String? _erro;

  int _paginaAtual = 1;

  @override
  void initState() {
    super.initState();
    _carregarObras();
  }

  // ===========================================================================
  // CARREGAR OBRAS
  // ===========================================================================

  Future<void> _carregarObras() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _paginaAtual = 1;
    });

    try {
      final resultado =
      await _obrasRepository.carregarPorCategoria(
        widget.categoria,
      );

      if (!mounted) return;

      setState(() {
        _obras = resultado;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar as obras.';
        _carregando = false;
      });
    }
  }

  // ===========================================================================
  // PAGINAÇÃO
  // ===========================================================================

  int get _totalPaginas {
    if (_obras.isEmpty) return 0;

    return (_obras.length / _itensPorPagina).ceil();
  }

  List<Obra> get _obrasPaginaAtual {
    if (_obras.isEmpty) {
      return [];
    }

    final inicio =
        (_paginaAtual - 1) * _itensPorPagina;

    if (inicio >= _obras.length) {
      return [];
    }

    final fim =
    (inicio + _itensPorPagina > _obras.length)
        ? _obras.length
        : inicio + _itensPorPagina;

    return _obras.sublist(inicio, fim);
  }

  void _alterarPagina(int pagina) {
    if (pagina < 1 || pagina > _totalPaginas) {
      return;
    }

    setState(() {
      _paginaAtual = pagina;
    });
  }

  // ===========================================================================
  // ABRIR DETALHES DA OBRA
  // ===========================================================================

  Future<void> _mostrarDetalhes(Obra obra) async {
    await mostrarDetalhesObraDialog(
      context,
      obra: obra,
      mostrarAbrir: true,
      onAbrir: () => _abrirDocumento(obra),
    );
  }

  // ===========================================================================
  // ABRIR DOCUMENTO
  // ===========================================================================

  Future<void> _abrirDocumento(Obra obra) async {
    final url = obra.urlDocumento;

    if (url.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta obra não possui um documento disponível.',
          ),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O endereço do documento é inválido.',
          ),
        ),
      );

      return;
    }

    final abriu = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FUNDO BRANCO
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,

        // Nome da categoria aparece apenas uma vez.
        title: Text(
          widget.categoria,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),

        // BOTÃO "VOLTAR" REMOVIDO
        actions: const [],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: _buildConteudo(),
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTEÚDO
  // ===========================================================================

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
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _carregarObras,
                child: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O título da categoria que estava repetido
          // foi removido daqui.

          Text(
            'Obras disponíveis nesta categoria.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 24),

          if (_obras.isEmpty)
            _buildSemResultados()
          else
            _buildListaObras(),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEM RESULTADOS
  // ===========================================================================

  Widget _buildSemResultados() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(32),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 42,
            color: Colors.grey,
          ),

          SizedBox(height: 12),

          Text(
            'Nenhuma obra encontrada',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Ainda não existem obras publicadas nesta categoria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LISTA DE OBRAS + PAGINAÇÃO
  // ===========================================================================

  Widget _buildListaObras() {
    final obrasPagina = _obrasPaginaAtual;

    return Column(
      children: [
        // ---------------------------------------------------------------------
        // OBRAS DA PÁGINA ATUAL
        // ---------------------------------------------------------------------

        ...obrasPagina.map((obra) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 1),

            child: ObraListaItem(
              obra: obra,

              onTap: () {
                context.go('/obra/${obra.id}');
              },

              mobile:
              MediaQuery.of(context).size.width < 700,
            ),
          );
        }),

        // ---------------------------------------------------------------------
        // PAGINAÇÃO
        // ---------------------------------------------------------------------

        if (_totalPaginas > 1)
          Paginacao(
            paginaAtual: _paginaAtual,
            totalPaginas: _totalPaginas,
            onPaginaChanged: _alterarPagina,
          ),
      ],
    );
  }
}
