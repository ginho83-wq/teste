import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/anuncio.dart';

class AnuncioVideo extends StatefulWidget {
  final Anuncio anuncio;

  const AnuncioVideo({
    super.key,
    required this.anuncio,
  });

  @override
  State<AnuncioVideo> createState() => _AnuncioVideoState();
}

class _AnuncioVideoState extends State<AnuncioVideo> {
  VideoPlayerController? _controller;
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _inicializarVideo();
  }

  Future<void> _inicializarVideo() async {
    final url = widget.anuncio.urlVideo;

    if (url == null || url.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = true;
        });
      }
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      await controller.initialize();

      controller.setLooping(true);

      if (mounted) {
        setState(() {
          _controller = controller;
          _carregando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _abrirAnuncio() async {
    final link = widget.anuncio.linkDestino;

    if (link == null || link.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(link);

    if (uri == null) {
      return;
    }

    await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
    );
  }

  void _alternarReproducao() {
    final controller = _controller;

    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    setState(() {});
  }

  void _alternarSom() {
    final controller = _controller;

    if (controller == null) return;

    final volume = controller.value.volume;

    controller.setVolume(volume > 0 ? 0 : 1);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E3E7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text(
              'Publicidade',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                letterSpacing: 0.3,
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildVideo(),
          ),
          if (widget.anuncio.titulo.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                widget.anuncio.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202124),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    if (_carregando) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_erro || _controller == null) {
      return Container(
        color: const Color(0xFFF8F9FA),
        alignment: Alignment.center,
        child: const Icon(
          Icons.video_library_outlined,
          size: 38,
          color: Color(0xFF9AA0A6),
        ),
      );
    }

    final controller = _controller!;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _alternarReproducao,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        Positioned(
          left: 10,
          bottom: 10,
          child: _BotaoVideo(
            icon: controller.value.isPlaying
                ? Icons.pause
                : Icons.play_arrow,
            onPressed: _alternarReproducao,
          ),
        ),

        Positioned(
          right: 10,
          bottom: 10,
          child: _BotaoVideo(
            icon: controller.value.volume > 0
                ? Icons.volume_up
                : Icons.volume_off,
            onPressed: _alternarSom,
          ),
        ),

        if (widget.anuncio.linkDestino != null &&
            widget.anuncio.linkDestino!.trim().isNotEmpty)
          Positioned(
            right: 10,
            top: 10,
            child: _BotaoVideo(
              icon: Icons.open_in_new,
              onPressed: _abrirAnuncio,
            ),
          ),
      ],
    );
  }
}

class _BotaoVideo extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _BotaoVideo({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
