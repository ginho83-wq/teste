import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/citacoes_obras_service.dart';
import '../widgets/contador_citacoes.dart';
import '../widgets/lista_citacoes.dart';

class CitacoesObrasPage extends StatefulWidget {
  final String obraId;
  final String titulo;
  final String autor;
  final int? ano;
  final String? url;

  const CitacoesObrasPage({
    super.key,
    required this.obraId,
    required this.titulo,
    required this.autor,
    this.ano,
    this.url,
  });

  @override
  State<CitacoesObrasPage> createState() =>
      _CitacoesObrasPageState();
}

class _CitacoesObrasPageState
    extends State<CitacoesObrasPage> {
  String? _citacaoGerada;

  String? _tipoCitacaoSelecionado;

  bool _gerando = false;
  bool _copiando = false;

  final CitacoesObrasService _service =
      CitacoesObrasService.instance;

  /// Apresenta o diálogo de seleção da norma.
  Future<String?> _mostrarDialogoNormas() async {
    String normaSelecionada =
        _tipoCitacaoSelecionado ?? 'APA 7';

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextDialogo, setStateDialogo) {
            return AlertDialog(
              title: const Text(
                'Escolher norma bibliográfica',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selecione a norma que pretende utilizar '
                          'para gerar a referência bibliográfica.',
                    ),
                    const SizedBox(height: 12),

                    RadioListTile<String>(
                      value: 'APA 7',
                      groupValue: normaSelecionada,
                      title: const Text('APA 7.ª edição'),
                      subtitle: const Text(
                        'American Psychological Association',
                      ),
                      onChanged: (valor) {
                        if (valor == null) return;

                        setStateDialogo(() {
                          normaSelecionada = valor;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      value: 'ABNT',
                      groupValue: normaSelecionada,
                      title: const Text('ABNT'),
                      subtitle: const Text(
                        'Normas brasileiras de documentação',
                      ),
                      onChanged: (valor) {
                        if (valor == null) return;

                        setStateDialogo(() {
                          normaSelecionada = valor;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      value: 'Vancouver',
                      groupValue: normaSelecionada,
                      title: const Text('Vancouver'),
                      subtitle: const Text(
                        'Utilizada frequentemente na área da saúde',
                      ),
                      onChanged: (valor) {
                        if (valor == null) return;

                        setStateDialogo(() {
                          normaSelecionada = valor;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      value: 'IEEE',
                      groupValue: normaSelecionada,
                      title: const Text('IEEE'),
                      subtitle: const Text(
                        'Utilizada frequentemente nas engenharias',
                      ),
                      onChanged: (valor) {
                        if (valor == null) return;

                        setStateDialogo(() {
                          normaSelecionada = valor;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      value: 'ISO 690',
                      groupValue: normaSelecionada,
                      title: const Text('ISO 690'),
                      subtitle: const Text(
                        'Norma internacional para referências',
                      ),
                      onChanged: (valor) {
                        if (valor == null) return;

                        setStateDialogo(() {
                          normaSelecionada = valor;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      normaSelecionada,
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Gera e regista a referência bibliográfica.
  Future<void> _criarCitacao() async {
    if (_gerando) return;

    final norma = await _mostrarDialogoNormas();

    if (!mounted || norma == null) return;

    setState(() {
      _gerando = true;
      _tipoCitacaoSelecionado = norma;
      _citacaoGerada = null;
    });

    try {
      final citacao = _service.gerarCitacao(
        norma: norma,
        titulo: widget.titulo,
        autor: widget.autor,
        ano: widget.ano,
        url: widget.url,
      );

      if (!mounted) return;

      setState(() {
        _citacaoGerada = citacao;
      });

      final user =
          Supabase.instance.client.auth.currentUser;

      if (user != null) {
        await _service.registarCitacao(
          obraId: widget.obraId,
          textoCitacao: citacao,
          tipoCitacao: norma,
          urlCitacao: widget.url,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user == null
                ? 'Referência gerada. Inicie sessão para a registar.'
                : 'Referência $norma gerada e registada com sucesso.',
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível gerar ou registar a referência: $e',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gerando = false;
        });
      }
    }
  }

  /// Copia a referência para a área de transferência.
  Future<void> _copiarCitacao() async {
    final citacao = _citacaoGerada;

    if (citacao == null ||
        citacao.isEmpty ||
        _copiando) {
      return;
    }

    setState(() {
      _copiando = true;
    });

    try {
      await Clipboard.setData(
        ClipboardData(text: citacao),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Referência copiada para a área de transferência.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível copiar a referência.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _copiando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final autor = widget.autor.trim().isEmpty
        ? 'Não identificado'
        : widget.autor.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Citações da obra'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 850,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.titulo,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),

                  const SizedBox(height: 8),

                  Text('Autor: $autor'),

                  if (widget.ano != null) ...[
                    const SizedBox(height: 4),
                    Text('Ano: ${widget.ano}'),
                  ],

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Referência bibliográfica',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Gere uma referência bibliográfica '
                                'selecionando a norma pretendida. '
                                'A referência poderá ser copiada '
                                'e, quando iniciar sessão, registada '
                                'na plataforma.',
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                              _gerando ? null : _criarCitacao,
                              icon: _gerando
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(
                                Icons.format_quote,
                              ),
                              label: Text(
                                _gerando
                                    ? 'A gerar...'
                                    : 'Criar citação',
                              ),
                            ),
                          ),

                          if (_citacaoGerada != null) ...[
                            const SizedBox(height: 20),

                            Text(
                              'Norma selecionada: '
                                  '${_tipoCitacaoSelecionado ?? 'APA 7'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge,
                            ),

                            const SizedBox(height: 8),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                _citacaoGerada!,
                                style: const TextStyle(
                                  height: 1.6,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            OutlinedButton.icon(
                              onPressed: _copiando
                                  ? null
                                  : _copiarCitacao,
                              icon: const Icon(Icons.copy),
                              label: Text(
                                _copiando
                                    ? 'A copiar...'
                                    : 'Copiar referência',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Referências registadas',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),

                  const SizedBox(height: 12),

                  ContadorCitacoes(
                    key: ValueKey(
                      'contador-${widget.obraId}',
                    ),
                    obraId: widget.obraId,
                  ),

                  const SizedBox(height: 16),

                  ListaCitacoes(
                    key: ValueKey(
                      'lista-${widget.obraId}',
                    ),
                    obraId: widget.obraId,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

