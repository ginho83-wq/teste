import 'package:flutter/material.dart';

class PlataformaPage extends StatelessWidget {
  const PlataformaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: const Text(
          'Obra Livre',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Voltar',
              style: TextStyle(
                color: Color(0xFF444444),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 18),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCabecalho(),
            _buildFuncionalidades(),
            _buildRodape(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        55,
        24,
        42,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          child: Column(
            children: const [
              Icon(
                Icons.apps_outlined,
                size: 42,
                color: Color(0xFF444444),
              ),
              SizedBox(height: 20),
              Text(
                'Conheça a plataforma',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222222),
                  height: 1.2,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Conheça as principais funcionalidades '
                    'disponíveis no Obra Livre.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuncionalidades() {
    const funcionalidades = [
      _Funcionalidade(
        titulo: 'Pesquisar obras',
        descricao:
        'Pesquise trabalhos académicos, científicos '
            'e literários disponíveis na plataforma.',
        icone: Icons.search_outlined,
      ),
      _Funcionalidade(
        titulo: 'Acervo',
        descricao:
        'Consulte e explore as obras disponíveis '
            'no acervo da plataforma.',
        icone: Icons.library_books_outlined,
      ),
      _Funcionalidade(
        titulo: 'Tese de Doutoramento',
        descricao:
        'Encontre trabalhos académicos correspondentes '
            'a teses de doutoramento.',
        icone: Icons.school_outlined,
      ),
      _Funcionalidade(
        titulo: 'Dissertação de Mestrado',
        descricao:
        'Consulte dissertações de mestrado disponibilizadas '
            'na plataforma.',
        icone: Icons.menu_book_outlined,
      ),
      _Funcionalidade(
        titulo: 'Monografia',
        descricao:
        'Explore monografias académicas publicadas '
            'no acervo.',
        icone: Icons.description_outlined,
      ),
      _Funcionalidade(
        titulo: 'Artigos Científicos',
        descricao:
        'Consulte artigos científicos disponíveis '
            'para pesquisa e leitura.',
        icone: Icons.article_outlined,
      ),
      _Funcionalidade(
        titulo: 'Literatura',
        descricao:
        'Explore obras literárias disponíveis '
            'na plataforma.',
        icone: Icons.auto_stories_outlined,
      ),
      _Funcionalidade(
        titulo: 'Publicar uma obra',
        descricao:
        'Envie uma obra para análise e posterior '
            'publicação na plataforma.',
        icone: Icons.upload_file_outlined,
      ),
      _Funcionalidade(
        titulo: 'Obras consultadas',
        descricao:
        'Consulte o histórico das obras que já '
            'foram consultadas.',
        icone: Icons.history_outlined,
      ),
      _Funcionalidade(
        titulo: 'Minha conta',
        descricao:
        'Área destinada à gestão das informações '
            'da conta do utilizador.',
        icone: Icons.person_outline,
      ),
      _Funcionalidade(
        titulo: 'Configurações',
        descricao:
        'Opções para configurar e personalizar '
            'a experiência do utilizador.',
        icone: Icons.settings_outlined,
      ),
      _Funcionalidade(
        titulo: 'Autenticação',
        descricao:
        'Acesso através de conta própria ou '
            'continuação com Google.',
        icone: Icons.lock_outline,
      ),
      _Funcionalidade(
        titulo: 'Administração',
        descricao:
        'Área administrativa destinada à gestão '
            'das obras e solicitações da plataforma.',
        icone: Icons.admin_panel_settings_outlined,
      ),
      _Funcionalidade(
        titulo: 'Ajuda',
        descricao:
        'Informações e orientações para utilização '
            'da plataforma.',
        icone: Icons.help_outline,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        10,
        24,
        60,
      ),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largura = constraints.maxWidth;

              final colunas = largura >= 950
                  ? 3
                  : largura >= 650
                  ? 2
                  : 1;

              const espacamento = 18.0;

              final itemLargura = colunas == 1
                  ? largura
                  : (largura -
                  ((colunas - 1) * espacamento)) /
                  colunas;

              return Wrap(
                spacing: espacamento,
                runSpacing: espacamento,
                children: funcionalidades.map(
                      (funcionalidade) {
                    return SizedBox(
                      width: itemLargura,
                      child: _buildCartao(
                        funcionalidade,
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCartao(
      _Funcionalidade funcionalidade,
      ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        border: Border.all(
          color: const Color(0xFFE6E6E6),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE1E1E1),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              funcionalidade.icone,
              size: 23,
              color: const Color(0xFF444444),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  funcionalidade.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  funcionalidade.descricao,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE8E8E8),
          ),
        ),
      ),
      child: const Center(
        child: Text(
          'Obra Livre',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF777777),
          ),
        ),
      ),
    );
  }
}

class _Funcionalidade {
  final String titulo;
  final String descricao;
  final IconData icone;

  const _Funcionalidade({
    required this.titulo,
    required this.descricao,
    required this.icone,
  });
}
