import 'package:flutter/material.dart';
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

  final HistoricoObrasService
  _historicoService =
  HistoricoObrasService();

  List<Obra> _obras = [];

  bool _carregando = true;

  String get _query =>
      widget.query?.trim() ?? '';

  String get _categoria =>
      widget.categoria?.trim() ?? '';

  String get _obraId =>
      widget.obraId?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ============================================================
  // CARREGAR OBRAS
  // ============================================================

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      List<Obra> resultado;

      if (_obraId.isNotEmpty) {
        final obra =
        await _repository.carregarPorId(
          _obraId,
        );

        resultado =
        obra != null ? [obra] : [];
      } else if (_categoria.isNotEmpty) {
        resultado =
        await _repository.carregarPorCategoria(
          _categoria,
        );
      } else if (_query.isNotEmpty) {
        resultado =
        await _repository.pesquisar(
          _query,
        );
      } else {
        resultado =
        await _repository.carregarObras(
          pagina: 1,
          limite: 10,
        );
      }

      if (!mounted) return;

      setState(() {
        _obras = resultado;
        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao carregar obras: $e',
      );

      if (!mounted) return;

      setState(() {
        _obras = [];
        _carregando = false;
      });
    }
  }

  // ============================================================
  // ABRIR DOCUMENTO
  // ============================================================

  Future<void> _abrirDocumento(
      Obra obra,
      ) async {
    final url =
    obra.urlDocumento.trim();

    if (url.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Esta obra não possui documento disponível.',
          ),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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

      debugPrint(
        'ACERVO: documento aberto: $abriu',
      );

      if (!abriu) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o documento.',
            ),
          ),
        );

        return;
      }
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao abrir documento: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );

      return;
    }

    try {
      await _historicoService
          .registrarConsulta(
        obraId: obra.id,
      );

      debugPrint(
        'ACERVO: consulta registrada: ${obra.id}',
      );
    } catch (e) {
      debugPrint(
        'ACERVO: erro ao registrar histórico: $e',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    String titulo = 'Acervo';

    if (_obraId.isNotEmpty &&
        _obras.length == 1) {
      titulo = 'Obra';
    } else if (_categoria.isNotEmpty) {
      titulo = _categoria;
    } else if (_query.isNotEmpty) {
      titulo =
      'Resultados para "$_query"';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _obras.isEmpty
          ? const Center(
        child: Text(
          'Nenhuma obra encontrada.',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      )
          : ListView.builder(
        padding:
        const EdgeInsets.all(24),
        itemCount: _obras.length,
        itemBuilder:
            (context, index) {
          final obra =
          _obras[index];

          return _ObraResultadoCard(
            obra: obra,
            onAbrir: () async {
              await _abrirDocumento(
                obra,
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// CARD DE RESULTADO
// ============================================================

class _ObraResultadoCard
    extends StatelessWidget {
  final Obra obra;
  final VoidCallback onAbrir;

  const _ObraResultadoCard({
    required this.obra,
    required this.onAbrir,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(6),
        side: const BorderSide(
          color: Color(0xffe2e2e2),
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              obra.titulo,
              style:
              const TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              obra.autor,
              style:
              const TextStyle(
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              obra.categoria,
              style:
              const TextStyle(
                fontSize: 13,
                color: Colors.black45,
              ),
            ),

            if (obra.descricao != null &&
                obra.descricao!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                obra.descricao!,
                maxLines: 3,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  color: Colors.black87,
                ),
              ),
            ],

            const SizedBox(height: 18),

            Align(
              alignment:
              Alignment.centerRight,
              child:
              ElevatedButton.icon(
                onPressed: onAbrir,
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
