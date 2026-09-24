import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';

class ObraDetalhesPage extends StatefulWidget {
  final String id;

  const ObraDetalhesPage({
    super.key,
    required this.id,
  });

  @override
  State<ObraDetalhesPage> createState() => _ObraDetalhesPageState();
}

class _ObraDetalhesPageState extends State<ObraDetalhesPage> {
  final ObrasRepository _repository = ObrasRepository.instancia;

  Obra? _obra;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarObra();
  }

  Future<void> _carregarObra() async {
    try {
      final obra = await _repository.carregarPorId(widget.id);

      if (!mounted) return;

      setState(() {
        _obra = obra;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar esta obra.';
        _carregando = false;
      });
    }
  }

  Future<void> _abrirDocumento() async {
    final obra = _obra;

    if (obra == null || obra.urlDocumento.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(obra.urlDocumento);

    if (uri == null) {
      return;
    }

    await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Obra'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _erro!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final obra = _obra;

    if (obra == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Obra não encontrada'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'A obra que procura não foi encontrada.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Title(
      title: '${obra.titulo} — Obra Livre',
      color: Colors.white,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Obra'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 900,
              ),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        obra.titulo,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _Informacao(
                        titulo: 'Autor',
                        valor: obra.autor,
                      ),

                      const SizedBox(height: 16),

                      _Informacao(
                        titulo: 'Categoria',
                        valor: obra.categoria,
                      ),

                      if (obra.anoObra != null) ...[
                        const SizedBox(height: 16),
                        _Informacao(
                          titulo: 'Ano da obra',
                          valor: obra.anoObra.toString(),
                        ),
                      ],

                      const SizedBox(height: 16),

                      _Informacao(
                        titulo: 'Data de publicação',
                        valor: _formatarData(
                          obra.dataPublicacao,
                        ),
                      ),

                      if (obra.descricao != null &&
                          obra.descricao!.trim().isNotEmpty) ...[
                        const SizedBox(height: 28),

                        Text(
                          'Descrição',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          obra.descricao!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge,
                        ),
                      ],

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                          obra.urlDocumento.trim().isEmpty
                              ? null
                              : _abrirDocumento,
                          icon: const Icon(
                            Icons.open_in_new,
                          ),
                          label: const Text(
                            'Abrir documento',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Informacao extends StatelessWidget {
  final String titulo;
  final String valor;

  const _Informacao({
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
