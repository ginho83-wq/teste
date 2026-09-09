import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              _link(
                context,
                'Termos',
                    () {
                  context.push('/termos');
                },
              ),

              _separador(tema),

              _link(
                context,
                'Privacidade',
                    () {
                  context.push('/politica-privacidade');
                },
              ),

              _separador(tema),

              _link(
                context,
                'Contacto',
                    () {
                  context.push('/contacto');
                },
              ),

              _separador(tema),

              _link(
                context,
                'Cookies',
                    () {
                  context.push('/cookies');
                },
              ),

              _separador(tema),

              Text(
                'Obra Livre © 2026. Todos os direitos reservados.',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(
      BuildContext context,
      String texto,
      VoidCallback onPressed,
      ) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 4,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _separador(ThemeData tema) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: Text(
        '•',
        style: tema.textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

