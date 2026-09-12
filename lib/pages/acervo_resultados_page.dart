import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/historico_obras_service.dart';

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
  HistoricoObrasService();

  List<Obra> _resultados = [];

  bool _carregando = true;
  String? _erro;

  bool _consultaRegistrada = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final obraId = widget.obraId?.trim() ?? '';
      final categoria = widget.categoria?.trim() ?? '';
      final query = widget.query?.trim() ?? '';

      // ============================================================
      // 1. OBRA ESPECÍFICA
      // ============================================================
      if (obraId.isNotEmpty) {
        final obra =
        await _repository.carregarPorId(obraId);

        if (obra == null) {
          _resultados = [];
        } else {
          _resultados = [obra];

          // Regista a obra como consultada quando o utilizador
          // realmente abre a página da obra.
          if (!_consultaRegistrada) {
            try {
              await _historicoService.registrarConsulta(
                obraId: obra.id,
              );

              _consultaRegistrada = true;
            } catch (e) {
              debugPrint(
                'Erro ao registar consulta no histórico: $e',
              );
            }
          }
        }
      }

      // ============================================================
      // 2. PESQUISA POR CATEGORIA
      // ============================================================
      else if (categoria.isNotEmpty) {
        _resultados =
        await _repository.carregarPorCategoria(
          categoria,
        );
      }

      // ============================================================
      // 3. PESQUISA
      // ============================================================
      else if (query.isNotEmpty) {
        _resultados =
        await _repository.pesquisar(query);
      }

      // ============================================================
      // 4. ACERVO GERAL
      // ============================================================
      else {
        _resultados =
        await _repository.carregarObras(
          pagina: 1,
          limite: 10,
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar obras: $e');

      _erro =
      'Não foi possível carregar as obras.';
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _abrirDocumento(Obra obra) async {
    final url = obra.urlDocumento?.trim();

    if (url == null || url.isEmpty) {
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

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
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
    } catch (e) {
      debugPrint(
        'Erro ao abrir documento: $e',
      );
    }
  }

  void _voltar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ehObraEspecifica =
        widget.obraId?.trim().isNotEmpty == true;

    String titulo;

    if (ehObraEspecifica) {
      titulo = 'Obra';
    } else if ((widget.categoria ?? '').isNotEmpty) {
      titulo = widget.categoria!;
    } else if ((widget.query ?? '').isNotEmpty) {
      titulo = 'Resultados';
    } else {
      titulo = 'Acervo';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _voltar,
        ),
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
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_resultados.isEmpty) {
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

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _resultados.length,
      separatorBuilder: (_, __) =>
      const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final obra = _resultados[index];

        return _buildObraCard(obra);
      },
    );
  }

  Widget _buildObraCard(Obra obra) {
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
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              obra.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (obra.autor != null &&
                obra.autor!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Autor: ${obra.autor}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            if (obra.categoria != null &&
                obra.categoria!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Categoria: ${obra.categoria}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            if (obra.descricao != null &&
                obra.descricao!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                obra.descricao!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _abrirDocumento(obra),
                icon: const Icon(
                  Icons.open_in_new,
                  size: 18,
                ),
                label: const Text(
                  'Abrir documento',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
