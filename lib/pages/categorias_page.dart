import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoriasPage extends StatelessWidget {
  const CategoriasPage({super.key});

  static const List<_Categoria> _categorias = [
    _Categoria(
      nome: 'Tese de Doutoramento',
      descricao: 'Teses e trabalhos académicos de doutoramento.',
      icone: Icons.school_outlined,
    ),
    _Categoria(
      nome: 'Dissertação de Mestrado',
      descricao: 'Dissertações e trabalhos académicos de mestrado.',
      icone: Icons.menu_book_outlined,
    ),
    _Categoria(
      nome: 'Dissertação de Licenciatura',
      descricao: 'Trabalhos finais e dissertações de licenciatura.',
      icone: Icons.school_outlined,
    ),
    _Categoria(
      nome: 'Monografia',
      descricao: 'Monografias e trabalhos de conclusão.',
      icone: Icons.description_outlined,
    ),
    _Categoria(
      nome: 'Artigos Científicos',
      descricao: 'Artigos e publicações de carácter científico.',
      icone: Icons.article_outlined,
    ),
    _Categoria(
      nome: 'Comunicações Científicas',
      descricao: 'Comunicações apresentadas em eventos científicos.',
      icone: Icons.record_voice_over_outlined,
    ),
    _Categoria(
      nome: 'Posters',
      descricao: 'Posters académicos e apresentações científicas.',
      icone: Icons.dashboard_outlined,
    ),
    _Categoria(
      nome: 'Resumos',
      descricao: 'Resumos de trabalhos e comunicações académicas.',
      icone: Icons.summarize_outlined,
    ),
    _Categoria(
      nome: 'Relatórios Académicos',
      descricao: 'Relatórios de investigação, estágio e actividades académicas.',
      icone: Icons.assignment_outlined,
    ),
    _Categoria(
      nome: 'Trabalhos Académicos',
      descricao: 'Trabalhos realizados no âmbito de disciplinas e cursos.',
      icone: Icons.library_books_outlined,
    ),
  ];

  void _abrirCategoria(
      BuildContext context,
      String categoria,
      ) {
    context.go(
      '/categoria/${Uri.encodeComponent(categoria)}',
    );
  }

  void _abrirAcervo(BuildContext context) {
    context.go('/acervo');
  }

  void _abrirInicio(BuildContext context) {
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    final isDesktop = largura >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 24,
        title: const Text(
          'Categorias',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _abrirInicio(context),
            child: const Text(
              'Início',
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: OutlinedButton(
              onPressed: () => _abrirAcervo(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(
                  color: Color(0xFFD5D5D5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Acervo'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 18,
              vertical: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categorias',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore o acervo por área e tipo de publicação.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () => _abrirAcervo(context),
                  icon: const Icon(
                    Icons.library_books_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Explorar todo o Acervo',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(
                      color: Color(0xFFD5D5D5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: isDesktop
                      ? GridView.builder(
                    padding: const EdgeInsets.only(
                      bottom: 20,
                    ),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.65,
                    ),
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final categoria = _categorias[index];

                      return _CategoriaCard(
                        categoria: categoria,
                        onTap: () => _abrirCategoria(
                          context,
                          categoria.nome,
                        ),
                      );
                    },
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: 20,
                    ),
                    itemCount: _categorias.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final categoria = _categorias[index];

                      return _CategoriaCard(
                        categoria: categoria,
                        onTap: () => _abrirCategoria(
                          context,
                          categoria.nome,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final _Categoria categoria;
  final VoidCallback onTap;

  const _CategoriaCard({
    required this.categoria,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(
          color: Color(0xFFE1E1E1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  categoria.icone,
                  size: 23,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categoria.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver obras',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward,
                          size: 15,
                          color: Colors.black87,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Categoria {
  final String nome;
  final String descricao;
  final IconData icone;

  const _Categoria({
    required this.nome,
    required this.descricao,
    required this.icone,
  });
}

