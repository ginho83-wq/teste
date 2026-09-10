import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';

class AcervoResultadosPage extends StatefulWidget {
  final String? query;
  final String? categoria;

  const AcervoResultadosPage({
    super.key,
    this.query,
    this.categoria,
  });

  @override
  State<AcervoResultadosPage> createState() =>
      _AcervoResultadosPageState();
}

class _AcervoResultadosPageState
    extends State<AcervoResultadosPage> {
  final ObrasRepository _repository = ObrasRepository.instancia;

  List<Obra> _obras = [];

  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      List<Obra> resultado;

      final query = widget.query?.trim() ?? '';
      final categoria = widget.categoria?.trim() ?? '';

      if (categoria.isNotEmpty) {
        resultado = await _repository.carregarPorCategoria(
          categoria,
        );
      } else if (query.isNotEmpty) {
        resultado = await _repository.pesquisar(query);
      } else {
        resultado = await _repository.carregarObras(
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
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(e);
        _carregando = false;
      });
    }
  }

  String _mensagemErro(Object erro) {
    final texto = erro.toString();

    if (texto.startsWith('Exception: ')) {
      return texto.substring(11);
    }

    return texto;
  }

  String _tituloPagina() {
    final categoria = widget.categoria?.trim() ?? '';
    final query = widget.query?.trim() ?? '';

    if (categoria.isNotEmpty) {
      return categoria;
    }

    if (query.isNotEmpty) {
      return 'Resultados para "$query"';
    }

    return 'Acervo';
  }

  String _formatarData(DateTime data) {
    final local = data.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  Future<void> _abrirDocumento(Obra obra) async {
    final url = obra.urlDocumento.trim();

    if (url.isEmpty) {
      _mostrarMensagem(
        'O documento não possui um endereço válido.',
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      _mostrarMensagem(
        'Não foi possível abrir o documento.',
      );
      return;
    }

    final abriu = await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
    );

    if (!abriu && mounted) {
      _mostrarMensagem(
        'Não foi possível abrir o documento.',
      );
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tituloPagina()),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_obras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                size: 52,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma obra encontrada.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tente pesquisar utilizando outros termos.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1080,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  '${_obras.length} obra(s) encontrada(s)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),
                const SizedBox(height: 20),
                ..._obras.map(
                      (obra) => _ObraResultadoCard(
                    obra: obra,
                    data: _formatarData(
                      obra.dataPublicacao,
                    ),
                    onAbrir: () =>
                        _abrirDocumento(obra),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObraResultadoCard extends StatelessWidget {
  final Obra obra;
  final String data;
  final VoidCallback onAbrir;

  const _ObraResultadoCard({
    required this.obra,
    required this.data,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              obra.titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              obra.autor,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              obra.categoria,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
            if (obra.anoObra != null) ...[
              const SizedBox(height: 6),
              Text('Ano: ${obra.anoObra}'),
            ],
            const SizedBox(height: 6),
            Text('Publicada em $data'),
            if (obra.descricao != null &&
                obra.descricao!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                obra.descricao!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onAbrir,
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                ),
                label: const Text('Abrir documento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
