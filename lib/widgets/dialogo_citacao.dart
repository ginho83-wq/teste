import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/gerador_citacoes.dart';

class DialogoCitacao extends StatefulWidget {
  final String titulo;
  final String autor;
  final String? ano;
  final String? trecho;
  final int? pagina;
  final String? url;
  final String? obraId;

  const DialogoCitacao({
    super.key,
    required this.titulo,
    required this.autor,
    this.ano,
    this.trecho,
    this.pagina,
    this.url,
    this.obraId,
  });

  static Future<void> mostrar(
      BuildContext context, {
        required String titulo,
        required String autor,
        String? ano,
        String? trecho,
        int? pagina,
        String? url,
        String? obraId,
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
          obraId: obraId,
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
  bool _copiando = false;

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

  /// Converte os estilos apresentados na interface
  /// para os formatos aceites pela Edge Function.
  String get _formatoParaNotificacao {
    switch (_estilo) {
      case 'APA 7':
        return 'APA';

      case 'ABNT':
        return 'ABNT';

      case 'Vancouver':
        return 'VANCOUVER';

      case 'IEEE':
      case 'ISO 690':
        return 'OUTRO';

      default:
        return 'OUTRO';
    }
  }

  /// Copia a citação e solicita a notificação do autor.
  Future<void> _copiar() async {
    if (_copiando) return;

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

    setState(() {
      _copiando = true;
    });

    try {
      // 1. Copiar primeiro para a área de transferência.
      await Clipboard.setData(
        ClipboardData(text: texto),
      );

      if (!mounted) return;

      // 2. Notificar o autor quando temos o identificador da obra.
      //
      // A função Supabase valida a sessão do utilizador,
      // regista a citação e tenta enviar o email ao autor.
      bool notificacaoEnviada = false;
      bool notificacaoProcessada = false;

      final obraId = widget.obraId?.trim();

      if (obraId != null && obraId.isNotEmpty) {
        try {
          final resposta = await Supabase.instance.client.functions
              .invoke(
            'notificar-citacao-obra',
            body: {
              'obra_id': obraId,
              'referencia': texto,
              'formato': _formatoParaNotificacao,
            },
          );

          final dados = resposta.data;

          if (dados is Map) {
            notificacaoProcessada = dados['success'] == true;
            notificacaoEnviada =
                dados['notification_sent'] == true;
          }
        } on FunctionException catch (erro) {
          // Uma falha de notificação não anula a cópia.
          debugPrint(
            'Erro na função de notificação de citação: '
                '${erro.status}: ${erro.details}',
          );
        } catch (erro) {
          debugPrint(
            'Não foi possível notificar o autor: $erro',
          );
        }
      }

      if (!mounted) return;

      // 3. Informar o utilizador sem impedir a cópia.
      String mensagem = 'Citação copiada com sucesso.';

      if (obraId == null || obraId.isEmpty) {
        mensagem =
        'Citação copiada. Não foi possível identificar a obra '
            'para notificar o autor.';
      } else if (notificacaoEnviada) {
        mensagem =
        'Citação copiada. O autor foi notificado por email.';
      } else if (notificacaoProcessada) {
        mensagem =
        'Citação copiada. O registo foi processado, '
            'mas não foi possível enviar o email.';
      } else {
        mensagem =
        'Citação copiada. Não foi possível confirmar '
            'a notificação do autor.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (erro) {
      if (!mounted) return;

      debugPrint('Erro ao copiar a citação: $erro');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível copiar a citação. Tente novamente.',
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
              // Cabeçalho.
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
                          borderRadius: BorderRadius.circular(6),
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

              // Rodapé.
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
                      onPressed: _copiando ? null : _copiar,
                      icon: _copiando
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.copy),
                      label: Text(
                        _copiando ? 'A copiar...' : 'Copiar citação',
                      ),
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
