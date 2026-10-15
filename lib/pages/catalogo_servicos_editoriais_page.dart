
import 'package:flutter/material.dart';

class CatalogoServicosEditoriaisPage extends StatefulWidget {
  const CatalogoServicosEditoriaisPage({super.key});

  @override
  State<CatalogoServicosEditoriaisPage> createState() =>
      _CatalogoServicosEditoriaisPageState();
}

class _CatalogoServicosEditoriaisPageState
    extends State<CatalogoServicosEditoriaisPage> {
  final Set<String> _servicosSelecionados = {};

  // Dados temporários para testar a interface.
  // Na Fase 4, serão substituídos pelos dados do Supabase.
  final List<_ServicoEditorial> _servicos = const [
    _ServicoEditorial(
      codigo: 'REVISAO_LINGUISTICA',
      nome: 'Revisão linguística',
      descricao:
      'Correção ortográfica, gramatical e de pontuação, '
          'com melhoria da clareza e da consistência do texto.',
      preco: 1500,
      icone: Icons.spellcheck_rounded,
    ),
    _ServicoEditorial(
      codigo: 'FORMATACAO_ACADEMICA',
      nome: 'Formatação académica',
      descricao:
      'Organização e formatação do documento segundo as '
          'normas académicas previamente acordadas.',
      preco: 2000,
      icone: Icons.description_outlined,
    ),
    _ServicoEditorial(
      codigo: 'REVISAO_REFERENCIAS',
      nome: 'Revisão de referências bibliográficas',
      descricao:
      'Verificação e organização das referências '
          'bibliográficas de acordo com o estilo escolhido.',
      preco: 1200,
      icone: Icons.menu_book_rounded,
    ),
    _ServicoEditorial(
      codigo: 'RESUMO_ABSTRACT',
      nome: 'Resumo e abstract',
      descricao:
      'Preparação ou revisão do resumo e do abstract '
          'para melhorar a clareza e a apresentação académica.',
      preco: 1000,
      icone: Icons.summarize_outlined,
    ),
    _ServicoEditorial(
      codigo: 'DIAGRAMACAO',
      nome: 'Diagramação',
      descricao:
      'Organização visual das páginas, títulos, tabelas '
          'e outros elementos do documento.',
      preco: 2500,
      icone: Icons.auto_awesome_mosaic_outlined,
    ),
    _ServicoEditorial(
      codigo: 'INDICE_AUTOMATICO',
      nome: 'Índice automático',
      descricao:
      'Criação ou correção do índice e organização '
          'dos títulos e subtítulos do documento.',
      preco: 800,
      icone: Icons.format_list_numbered_rounded,
    ),
  ];

  int get _totalSelecionado {
    return _servicos
        .where((servico) => _servicosSelecionados.contains(servico.codigo))
        .fold<int>(0, (total, servico) => total + servico.preco);
  }

  @override
  Widget build(BuildContext context) {
    final bool compacto = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FF),
        foregroundColor: const Color(0xFF17324D),
        elevation: 0,
        title: const Text(
          'Serviços editoriais',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compacto ? 16 : 32,
                vertical: 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Prepare a sua obra para publicação',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17324D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Escolha os serviços editoriais de que necessita. '
                            'A publicação da sua obra no acervo do Obra Livre '
                            'continua a ser gratuita.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Color(0xFF526579),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE8DCC4),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF8A5A00),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Os serviços são opcionais. Os preços '
                                    'apresentados nesta versão são ilustrativos '
                                    'e ainda não constituem preços oficiais.',
                                style: TextStyle(
                                  color: Color(0xFF6D501D),
                                  height: 1.6,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final int colunas =
                          constraints.maxWidth >= 850
                              ? 3
                              : constraints.maxWidth >= 560
                              ? 2
                              : 1;

                          const double espaco = 16;

                          final double largura =
                              (constraints.maxWidth -
                                  (colunas - 1) * espaco) /
                                  colunas;

                          return Wrap(
                            spacing: espaco,
                            runSpacing: espaco,
                            children: _servicos.map((servico) {
                              return SizedBox(
                                width: largura,
                                child: _CartaoServico(
                                  servico: servico,
                                  selecionado: _servicosSelecionados
                                      .contains(servico.codigo),
                                  onChanged: (selecionado) {
                                    setState(() {
                                      if (selecionado) {
                                        _servicosSelecionados
                                            .add(servico.codigo);
                                      } else {
                                        _servicosSelecionados
                                            .remove(servico.codigo);
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD5E5F5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Resumo da seleção',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF17324D),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_servicosSelecionados.length} '
                                  '${_servicosSelecionados.length == 1 ? 'serviço selecionado' : 'serviços selecionados'}',
                              style: const TextStyle(
                                color: Color(0xFF526579),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total ilustrativo: ${_formatarPreco(_totalSelecionado)} MZN',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1769AA),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _servicosSelecionados.isEmpty
                                    ? null
                                    : _mostrarResumo,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                ),
                                label: const Text(
                                  'Continuar com a seleção',
                                  textAlign: TextAlign.center,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF1769AA),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                  const Color(0xFFD8E0E8),
                                  disabledForegroundColor:
                                  const Color(0xFF718096),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarPreco(int valor) {
    final texto = valor.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(texto[i]);
    }

    return buffer.toString();
  }

  void _mostrarResumo() {
    final selecionados = _servicos
        .where((servico) => _servicosSelecionados.contains(servico.codigo))
        .toList();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Serviços selecionados'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final servico in selecionados) ...[
                    Text(
                      servico.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${_formatarPreco(servico.preco)} MZN'),
                    const SizedBox(height: 12),
                  ],
                  const Divider(),
                  Text(
                    'Total ilustrativo: '
                        '${_formatarPreco(_totalSelecionado)} MZN',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1769AA),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esta é uma pré-visualização. O pedido ainda '
                        'não será guardado nem enviado.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF65788A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Voltar ao catálogo'),
            ),
          ],
        );
      },
    );
  }
}

class _ServicoEditorial {
  final String codigo;
  final String nome;
  final String descricao;
  final int preco;
  final IconData icone;

  const _ServicoEditorial({
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.icone,
  });
}

class _CartaoServico extends StatelessWidget {
  final _ServicoEditorial servico;
  final bool selecionado;
  final ValueChanged<bool> onChanged;

  const _CartaoServico({
    required this.servico,
    required this.selecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF1769AA);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selecionado
              ? azul
              : const Color(0xFFE0E8EF),
          width: selecionado ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: azul.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  servico.icone,
                  color: azul,
                  size: 25,
                ),
              ),
              const Spacer(),
              Checkbox(
                value: selecionado,
                activeColor: azul,
                onChanged: (valor) => onChanged(valor ?? false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            servico.nome,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.35,
              color: Color(0xFF17324D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            servico.descricao,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF526579),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE6EDF3)),
          const SizedBox(height: 12),
          Text(
            '${_formatarPrecoEstatico(servico.preco)} MZN',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: azul,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Preço ilustrativo',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8B9A),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onChanged(!selecionado),
              style: OutlinedButton.styleFrom(
                foregroundColor: selecionado ? Colors.white : azul,
                backgroundColor:
                selecionado ? azul : Colors.transparent,
                side: const BorderSide(color: azul),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                selecionado ? 'Selecionado' : 'Selecionar serviço',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatarPrecoEstatico(int valor) {
  final texto = valor.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(texto[i]);
  }

  return buffer.toString();
}
