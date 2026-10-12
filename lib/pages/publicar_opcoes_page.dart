import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PublicarOpcoesPage extends StatelessWidget {
  const PublicarOpcoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool compacto = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),

      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FF),
        foregroundColor: const Color(0xFF17324D),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Opções de publicação',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFD5E5F5),
          ),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 16 : 32,
            vertical: 28,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1050,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cabeçalho da página
                const Text(
                  'Como pretende publicar a sua obra?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17324D),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Escolha a opção que melhor corresponde às suas '
                      'necessidades. No Obra Livre, a publicação da sua obra '
                      'no acervo digital é gratuita.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF526579),
                  ),
                ),

                const SizedBox(height: 30),

                // Cartão informativo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD5E5F5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF1769AA),
                        size: 27,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Importante',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF17324D),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Todas as obras submetidas passam pelo '
                                  'processo normal de análise e aprovação antes '
                                  'de serem disponibilizadas publicamente.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF40566B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Opções responsivas.
                //
                // Em ecrãs pequenos, utiliza Column sem Expanded.
                // Em ecrãs grandes, utiliza Row com Expanded.
                // Esta separação evita constrangimentos de altura infinita
                // provocados pelo Flex vertical dentro do ScrollView.
                if (compacto) ...[
                  _CartaoOpcao(
                    icone: Icons.menu_book_rounded,
                    titulo: 'Publicação gratuita',
                    destaque: '0 MZN',
                    descricao:
                    'Publique a sua obra no acervo digital do Obra Livre, '
                        'sujeita ao processo normal de análise e aprovação.',
                    itens: const [
                      'Publicação no acervo',
                      'Página própria da obra',
                      'Disponibilização do PDF',
                      'Análise da publicação',
                    ],
                    textoBotao: 'Publicar gratuitamente',
                    cor: const Color(0xFF1769AA),
                    preenchido: true,
                    onPressed: () {
                      context.push('/publicar');
                    },
                  ),

                  const SizedBox(height: 20),

                  _CartaoOpcao(
                    icone: Icons.auto_awesome_rounded,
                    titulo: 'Publicação + Serviços Editoriais',
                    destaque: 'Serviços opcionais',
                    descricao:
                    'Além da publicação gratuita, escolha serviços '
                        'editoriais para preparar, melhorar ou apresentar '
                        'profissionalmente a sua obra.',
                    itens: const [
                      'Publicação no acervo',
                      'Escolha dos serviços editoriais',
                      'Serviços com preços definidos',
                      'Pedido editorial personalizado',
                    ],
                    textoBotao: 'Conhecer serviços editoriais',
                    cor: const Color(0xFF7A4E00),
                    preenchido: false,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'O catálogo de serviços editoriais será '
                                'disponibilizado nesta próxima fase.',
                          ),
                        ),
                      );
                    },
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CartaoOpcao(
                          icone: Icons.menu_book_rounded,
                          titulo: 'Publicação gratuita',
                          destaque: '0 MZN',
                          descricao:
                          'Publique a sua obra no acervo digital do '
                              'Obra Livre, sujeita ao processo normal de '
                              'análise e aprovação.',
                          itens: const [
                            'Publicação no acervo',
                            'Página própria da obra',
                            'Disponibilização do PDF',
                            'Análise da publicação',
                          ],
                          textoBotao: 'Publicar gratuitamente',
                          cor: const Color(0xFF1769AA),
                          preenchido: true,
                          onPressed: () {
                            context.push('/publicar');
                          },
                        ),
                      ),

                      const SizedBox(width: 24),

                      Expanded(
                        child: _CartaoOpcao(
                          icone: Icons.auto_awesome_rounded,
                          titulo: 'Publicação + Serviços Editoriais',
                          destaque: 'Serviços opcionais',
                          descricao:
                          'Além da publicação gratuita, escolha '
                              'serviços editoriais para preparar, melhorar '
                              'ou apresentar profissionalmente a sua obra.',
                          itens: const [
                            'Publicação no acervo',
                            'Escolha dos serviços editoriais',
                            'Serviços com preços definidos',
                            'Pedido editorial personalizado',
                          ],
                          textoBotao: 'Conhecer serviços editoriais',
                          cor: const Color(0xFF7A4E00),
                          preenchido: false,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'O catálogo de serviços editoriais será '
                                      'disponibilizado nesta próxima fase.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 28),

                // Informação final
                const Text(
                  'O Obra Livre promove o acesso e a disseminação '
                      'do conhecimento académico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF65788A),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoOpcao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String destaque;
  final String descricao;
  final List<String> itens;
  final String textoBotao;
  final Color cor;
  final bool preenchido;
  final VoidCallback onPressed;

  const _CartaoOpcao({
    required this.icone,
    required this.titulo,
    required this.destaque,
    required this.descricao,
    required this.itens,
    required this.textoBotao,
    required this.cor,
    required this.preenchido,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: preenchido
              ? const Color(0xFFD5E5F5)
              : const Color(0xFFE8DCC4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icone,
              color: cor,
              size: 30,
            ),
          ),

          const SizedBox(height: 20),

          // Título
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 21,
              height: 1.3,
              fontWeight: FontWeight.bold,
              color: Color(0xFF17324D),
            ),
          ),

          const SizedBox(height: 12),

          // Destaque
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              destaque,
              style: TextStyle(
                color: cor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Descrição
          Text(
            descricao,
            style: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF526579),
            ),
          ),

          const SizedBox(height: 20),

          const Divider(
            height: 1,
            color: Color(0xFFE6EDF3),
          ),

          const SizedBox(height: 18),

          // Lista de funcionalidades
          for (final item in itens) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: cor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF40566B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          const SizedBox(height: 8),

          // Botão de ação
          SizedBox(
            width: double.infinity,
            child: preenchido
                ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
              ),
              label: Text(
                textoBotao,
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
              ),
              label: Text(
                textoBotao,
                textAlign: TextAlign.center,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cor,
                side: BorderSide(
                  color: cor,
                  width: 1.3,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
