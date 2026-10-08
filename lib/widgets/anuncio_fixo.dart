import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/anuncio.dart';

class AnuncioFixo extends StatelessWidget {
  final Anuncio anuncio;

  const AnuncioFixo({
    super.key,
    required this.anuncio,
  });

  Future<void> _abrirAnuncio() async {
    final link = anuncio.linkDestino;

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

  @override
  Widget build(BuildContext context) {
    final temImagem =
        anuncio.urlImagem != null &&
            anuncio.urlImagem!.trim().isNotEmpty;

    final temLink =
        anuncio.linkDestino != null &&
            anuncio.linkDestino!.trim().isNotEmpty;

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
            aspectRatio: 4 / 3,
            child: temImagem
                ? InkWell(
              onTap: temLink ? _abrirAnuncio : null,
              child: Image.network(
                anuncio.urlImagem!,
                fit: BoxFit.cover,
                loadingBuilder:
                    (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 38,
                      color: Color(0xFF9AA0A6),
                    ),
                  );
                },
              ),
            )
                : Container(
              color: const Color(0xFFF8F9FA),
              alignment: Alignment.center,
              child: const Icon(
                Icons.campaign_outlined,
                size: 40,
                color: Color(0xFF9AA0A6),
              ),
            ),
          ),
          if (anuncio.titulo.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                anuncio.titulo,
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
}
