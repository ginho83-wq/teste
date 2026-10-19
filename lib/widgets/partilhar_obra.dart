import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PartilharObra extends StatelessWidget {
  final String titulo;
  final String url;

  const PartilharObra({
    super.key,
    required this.titulo,
    required this.url,
  });

  /// Copia o link da obra para a área de transferência.
  Future<void> _copiarLink(BuildContext context) async {
    try {
      await Clipboard.setData(
        ClipboardData(text: url),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link da obra copiado com sucesso!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível copiar o link.'),
        ),
      );
    }
  }

  /// Abre a plataforma seleccionada para partilhar a obra.
  Future<void> _partilhar(
      BuildContext context,
      String destino,
      ) async {
    final mensagem = '$titulo\n$url';

    late final Uri endereco;

    switch (destino) {
      case 'whatsapp':
        endereco = Uri.https(
          'wa.me',
          '/',
          {'text': mensagem},
        );
        break;

      case 'facebook':
        endereco = Uri.https(
          'www.facebook.com',
          '/sharer/sharer.php',
          {'u': url},
        );
        break;

      case 'telegram':
        endereco = Uri.https(
          't.me',
          '/share/url',
          {
            'url': url,
            'text': titulo,
          },
        );
        break;

      case 'linkedin':
        endereco = Uri.https(
          'www.linkedin.com',
          '/sharing/share-offsite/',
          {'url': url},
        );
        break;

      case 'x':
        endereco = Uri.https(
          'twitter.com',
          '/intent/tweet',
          {
            'text': titulo,
            'url': url,
          },
        );
        break;

      case 'email':
        endereco = Uri(
          scheme: 'mailto',
          queryParameters: {
            'subject': 'Obra académica: $titulo',
            'body':
            'Olá!\n\n'
                'Partilho contigo esta obra académica '
                'disponível na plataforma Obra Livre:\n\n'
                '$titulo\n$url\n\n'
                'Acede à Obra Livre para consultar a obra.',
          },
        );
        break;

      default:
        return;
    }

    try {
      final aberto = await launchUrl(
        endereco,
        webOnlyWindowName: '_blank',
      );

      if (!aberto && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir a opção de partilha.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ocorreu um erro ao partilhar a obra.',
          ),
        ),
      );
    }
  }

  /// Alternativa para a partilha nativa no Flutter Web.
  Future<void> _partilharNativamente(
      BuildContext context,
      ) async {
    await _copiarLink(context);
  }

  /// Cria um item válido para o menu de partilha.
  PopupMenuEntry<String> _itemPartilha({
    required IconData icone,
    required String texto,
    required String destino,
  }) {
    return PopupMenuItem<String>(
      value: destino,
      child: Row(
        children: [
          Icon(icone),
          const SizedBox(width: 12),
          Text(texto),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão para copiar o link.
        IconButton(
          tooltip: 'Copiar link da obra',
          icon: const Icon(Icons.link),
          onPressed: () => _copiarLink(context),
        ),

        // Menu de partilha.
        PopupMenuButton<String>(
          tooltip: 'Partilhar obra',
          icon: const Icon(Icons.share_outlined),
          onSelected: (destino) {
            if (destino == 'nativo') {
              _partilharNativamente(context);
            } else {
              _partilhar(context, destino);
            }
          },
          itemBuilder: (context) => [
            _itemPartilha(
              icone: Icons.chat_outlined,
              texto: 'WhatsApp',
              destino: 'whatsapp',
            ),
            _itemPartilha(
              icone: Icons.facebook,
              texto: 'Facebook',
              destino: 'facebook',
            ),
            _itemPartilha(
              icone: Icons.send_outlined,
              texto: 'Telegram',
              destino: 'telegram',
            ),
            _itemPartilha(
              icone: Icons.work_outline,
              texto: 'LinkedIn',
              destino: 'linkedin',
            ),
            _itemPartilha(
              icone: Icons.alternate_email,
              texto: 'X (Twitter)',
              destino: 'x',
            ),

            const PopupMenuDivider(),
            _itemPartilha(
              icone: Icons.ios_share,
              texto: 'Mais opções',
              destino: 'nativo',
            ),
          ],
        ),

        const SizedBox(width: 8),
      ],
    );
  }
}

