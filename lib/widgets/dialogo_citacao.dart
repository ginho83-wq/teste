import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/gerador_citacoes.dart';

class DialogoCitacao extends StatefulWidget {
  final String titulo;
  final String autor;
  final String? ano;
  final String? trecho;
  final int? pagina;
  final String? url;

  const DialogoCitacao({
    super.key,
    required this.titulo,
    required this.autor,
    this.ano,
    this.trecho,
    this.pagina,
    this.url,
  });

  static Future<void> mostrar(
      BuildContext context, {
        required String titulo,
        required String autor,
        String? ano,
        String? trecho,
        int? pagina,
        String? url,
      }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return DialogoCitacao(
          titulo: titulo,
          autor: autor,
          ano: ano,
          trecho: trecho,
          pagina: pagina,
          url: url,
        );
      },
    );
  }

  @override
  State<DialogoCitacao> createState() => _DialogoCitacaoState();
}

class _DialogoCitacaoState extends State<DialogoCitacao> {
  String _estilo = 'APA 7';
  String _tipo = 'Citação direta';

  bool _maximizado = false;

  late final TextEditingController _trechoController;

  static const double _raio = 6.0;

  @override
  void initState() {
    super.initState();

    _trechoController = TextEditingController(
      text: widget.trecho ?? '',
    );
  }

  @override
  void dispose() {
    _trechoController.dispose();
    super.dispose();
  }

  String get _citacao {
    return GeradorCitacoes.gerar(
      estilo: _estilo,
      tipo: _tipo,
      titulo: widget.titulo,
      autor: widget.autor,
      ano: widget.ano,
      trecho: _trechoController.text,
      pagina: widget.pagina,
      url: widget.url,
    );
  }

  Future<void> _copiar() async {
    final texto = _citacao.trim();

    if (texto.isEmpty ||
        texto.startsWith('Selecione ou introduza')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Introduza ou selecione um trecho válido antes de copiar.',
          ),
        ),
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: texto),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Citação copiada com sucesso.'),
      ),
    );
  }

  void _alternarMaximizacao() {
    setState(() {
      _maximizado = !_maximizado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> estilos =
    GeradorCitacoes.estilos.cast<String>().toList();

    final List<String> tipos =
    GeradorCitacoes.tipos.cast<String>().toList();

    final tamanho = MediaQuery.sizeOf(context);

    final double margemHorizontal = _maximizado ? 8 : 24;
    final double margemVertical = _maximizado ? 8 : 24;

    final double larguraMaxima =
    _maximizado ? tamanho.width - 16 : 600;

    final double alturaMaxima =
    _maximizado ? tamanho.height - 16 : tamanho.height * 0.85;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: margemHorizontal,
        vertical: margemVertical,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_raio),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: larguraMaxima,
          maxHeight: alturaMaxima,
        ),
        child: SizedBox(
          width: larguraMaxima,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho com os cantos superiores arredondados.
              Container(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 8,
                  top: 8,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Criar citação',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: _maximizado
                          ? 'Restaurar tamanho'
                          : 'Maximizar diálogo',
                      onPressed: _alternarMaximizacao,
                      icon: Icon(
                        _maximizado
                            ? Icons.close_fullscreen
                            : Icons.open_in_full,
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo rolável.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: estilos.contains(_estilo)
                            ? _estilo
                            : estilos.firstOrNull,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Norma bibliográfica',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(6),
                            ),
                          ),
                        ),
                        items: estilos.map<DropdownMenuItem<String>>(
                              (estilo) {
                            return DropdownMenuItem<String>(
                              value: estilo,
                              child: Text(estilo),
                            );
                          },
                        ).toList(),
                        onChanged: (valor) {
                          if (valor == null) return;

                          setState(() {
                            _estilo = valor;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: tipos.contains(_tipo)
                            ? _tipo
                            : tipos.firstOrNull,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de citação',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(6),
                            ),
                          ),
                        ),
                        items: tipos.map<DropdownMenuItem<String>>(
                              (tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(tipo),
                            );
                          },
                        ).toList(),
                        onChanged: (valor) {
                          if (valor == null) return;

                          setState(() {
                            _tipo = valor;
                          });
                        },
                      ),

                      if (_tipo == 'Citação direta') ...[
                        const SizedBox(height: 16),

                        TextField(
                          controller: _trechoController,
                          minLines: 3,
                          maxLines: _maximizado ? 12 : 6,
                          decoration: const InputDecoration(
                            labelText: 'Trecho a citar',
                            hintText:
                            'Introduza o trecho selecionado...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),

                        if (widget.pagina != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Página: ${widget.pagina}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ],

                      const SizedBox(height: 20),

                      const Text(
                        'Resultado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: SelectableText(
                          _citacao,
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Rodapé com os cantos inferiores arredondados.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant,
                    ),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Fechar'),
                    ),
                    FilledButton.icon(
                      onPressed: _copiar,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar citação'),
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

