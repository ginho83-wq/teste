import 'package:flutter/material.dart';

import '../models/anuncio.dart';
import '../repositories/anuncios_repository.dart';
import 'anuncio_fixo.dart';
import 'anuncio_video.dart';

class ColunaAnuncios extends StatefulWidget {
  const ColunaAnuncios({
    super.key,
  });

  @override
  State<ColunaAnuncios> createState() => _ColunaAnunciosState();
}

class _ColunaAnunciosState extends State<ColunaAnuncios> {
  final AnunciosRepository _repository = AnunciosRepository();

  Anuncio? _video;
  Anuncio? _fixo;

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarAnuncios();
  }

  Future<void> _carregarAnuncios() async {
    Anuncio? video;
    Anuncio? fixo;

    // Carrega o vídeo independentemente.
    try {
      video = await _repository.carregarVideoPrincipal();
    } catch (e) {
      debugPrint('ERRO AO CARREGAR VÍDEO: $e');
    }

    // Carrega o anúncio fixo independentemente.
    try {
      fixo = await _repository.carregarAnuncioFixoPrincipal();
    } catch (e) {
      debugPrint('ERRO AO CARREGAR ANÚNCIO FIXO: $e');
    }

    if (!mounted) return;

    setState(() {
      _video = video;
      _fixo = fixo;
      _carregando = false;
    });

    debugPrint('----------------------------------------');
    debugPrint('COLUNA DE ANÚNCIOS');
    debugPrint('Vídeo: ${_video?.titulo ?? "nenhum"}');
    debugPrint('Fixo: ${_fixo?.titulo ?? "nenhum"}');
    debugPrint('----------------------------------------');
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const SizedBox(
        width: 300,
        height: 250,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_video == null && _fixo == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 300.0;

        final larguraAnuncio = largura.clamp(260.0, 300.0);

        return SizedBox(
          width: larguraAnuncio,
          child: _buildConteudo(),
        );
      },
    );
  }

  Widget _buildConteudo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_video != null)
          AnuncioVideo(
            anuncio: _video!,
          ),

        if (_video != null && _fixo != null)
          const SizedBox(height: 24),

        if (_fixo != null)
          _buildAnuncioFixoSticky(),
      ],
    );
  }

  Widget _buildAnuncioFixoSticky() {
    return Align(
      alignment: Alignment.topCenter,
      child: AnuncioFixo(
        anuncio: _fixo!,
      ),
    );
  }
}

