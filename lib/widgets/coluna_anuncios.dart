import 'package:flutter/material.dart';

import '../models/anuncio.dart';
import '../repositories/anuncios_repository.dart';
import 'anuncio_fixo.dart';
import 'anuncio_video.dart';

class ColunaAnuncios extends StatefulWidget {
  const ColunaAnuncios({super.key});

  @override
  State<ColunaAnuncios> createState() => _ColunaAnunciosState();
}

class _ColunaAnunciosState extends State<ColunaAnuncios> {
  final AnunciosRepository _repository = AnunciosRepository();

  Anuncio? _video;
  Anuncio? _fixo;

  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregarAnuncios();
  }

  Future<void> _carregarAnuncios() async {
    try {
      final resultados = await Future.wait([
        _repository.carregarVideoPrincipal(),
        _repository.carregarAnuncioFixoPrincipal(),
      ]);

      if (!mounted) return;

      setState(() {
        _video = resultados[0];
        _fixo = resultados[1];
        _erro = false;
        _carregando = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Erro ao carregar anúncios: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _erro = true;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(260.0, 300.0).toDouble()
            : 300.0;

        return SizedBox(
          width: largura,
          child: _buildConteudo(),
        );
      },
    );
  }

  Widget _buildConteudo() {
    // Enquanto os anúncios são carregados, o espaço não desaparece.
    if (_carregando) {
      return _buildPlaceholder(
        mensagem: 'A carregar publicidade...',
        mostrarCarregamento: true,
      );
    }

    // Se não houver anúncios ou ocorrer um erro,
    // mantém-se o espaço reservado para publicidade.
    if (_video == null && _fixo == null) {
      return _buildPlaceholder(
        mensagem: _erro
            ? 'Publicidade temporariamente indisponível.'
            : 'Espaço disponível para anunciar.',
      );
    }

    final widgets = <Widget>[];

    if (_video != null) {
      widgets.add(
        AnuncioVideo(anuncio: _video!),
      );
    }

    if (_fixo != null) {
      widgets.add(
        AnuncioFixo(anuncio: _fixo!),
      );
    }

    // Se existir apenas um anúncio, ele é apresentado normalmente.
    // Se existirem dois, são apresentados com espaçamento.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widgets.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          widgets[i],
        ],
      ],
    );
  }

  Widget _buildPlaceholder({
    required String mensagem,
    bool mostrarCarregamento = false,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 250,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        border: Border.all(
          color: const Color(0xFFD5E5F5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 42,
            color: Color(0xFF7890A8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Publicidade',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF26384A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
          if (mostrarCarregamento) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

