import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0B0B0B),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              48,
              24,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compacto = constraints.maxWidth < 650;

                    if (compacto) {
                      return _buildMobile(context);
                    }

                    return _buildDesktop(context);
                  },
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFF242424),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    const Text(
                      '© 2026 Obra Livre',
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Text(
                      'Todos os direitos reservados.',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildMarca(),
        ),

        const SizedBox(width: 80),

        Expanded(
          child: _buildColuna(
            titulo: 'Plataforma',
            links: [
              _FooterLink(
                'Acervo',
                    () => context.push('/acervo'),
              ),
              _FooterLink(
                'Publicar uma obra',
                    () => context.push('/publicar'),
              ),
            ],
          ),
        ),

        Expanded(
          child: _buildColuna(
            titulo: 'Informações',
            links: [
              _FooterLink(
                'Termos',
                    () => context.push('/termos'),
              ),
              _FooterLink(
                'Privacidade',
                    () => context.push('/politica-privacidade'),
              ),
              _FooterLink(
                'Cookies',
                    () => context.push('/cookies'),
              ),
            ],
          ),
        ),

        Expanded(
          child: _buildColuna(
            titulo: 'Ajuda',
            links: [
              _FooterLink(
                'Contacto',
                    () => context.push('/contacto'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMarca(),

        const SizedBox(height: 36),

        _buildColuna(
          titulo: 'Plataforma',
          links: [
            _FooterLink(
              'Acervo',
                  () => context.push('/acervo'),
            ),
            _FooterLink(
              'Publicar uma obra',
                  () => context.push('/publicar'),
            ),
          ],
        ),

        const SizedBox(height: 28),

        _buildColuna(
          titulo: 'Informações',
          links: [
            _FooterLink(
              'Termos',
                  () => context.push('/termos'),
            ),
            _FooterLink(
              'Privacidade',
                  () => context.push('/politica-privacidade'),
            ),
            _FooterLink(
              'Cookies',
                  () => context.push('/cookies'),
            ),
          ],
        ),

        const SizedBox(height: 28),

        _buildColuna(
          titulo: 'Ajuda',
          links: [
            _FooterLink(
              'Contacto',
                  () => context.push('/contacto'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarca() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Obra Livre',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),

        SizedBox(height: 12),

        Text(
          'Acervo digital de obras académicas,\n'
              'científicas e literárias.',
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildColuna({
    required String titulo,
    required List<_FooterLink> links,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 14),

        ...links.map(
              (link) => Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: _buildLink(link),
          ),
        ),
      ],
    );
  }

  Widget _buildLink(_FooterLink link) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: link.onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 2,
            ),
            child: Text(
              link.texto,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FooterLink {
  final String texto;
  final VoidCallback onTap;

  const _FooterLink(
      this.texto,
      this.onTap,
      );
}

