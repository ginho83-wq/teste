import 'package:flutter/material.dart';

import '../services/arquivo_service.dart';
import '../services/auth_service.dart';
import '../services/publicacao_service.dart';

class PublicarObraPage extends StatefulWidget {
  const PublicarObraPage({
    super.key,
  });

  @override
  State<PublicarObraPage> createState() =>
      _PublicarObraPageState();
}

class _PublicarObraPageState extends State<PublicarObraPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _autorController = TextEditingController();
  final _anoController = TextEditingController();

  final _authService = AuthService.instancia;
  final _arquivoService = ArquivoService.instancia;
  final _publicacaoService = PublicacaoService.instancia;

  String? _categoriaSelecionada;
  ArquivoSelecionado? _arquivoSelecionado;

  bool _publicando = false;

  final List<String> _categorias = const [
    'Tese de Doutoramento',
    'Dissertação de Mestrado',
    'Monografia',
    'Artigos Científicos',
    'Literatura',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _autorController.dispose();
    _anoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarPdf() async {
    try {
      final arquivo = await _arquivoService.selecionarPdf();

      if (!mounted || arquivo == null) {
        return;
      }

      setState(() {
        _arquivoSelecionado = arquivo;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        _mensagemErro(e),
        erro: true,
      );
    }
  }

  Future<void> _publicar() async {
    if (_publicando) return;

    final usuario = _authService.usuarioAtual;

    if (usuario == null) {
      _mostrarMensagem(
        'É necessário iniciar sessão para publicar uma obra.',
        erro: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSelecionada == null ||
        _categoriaSelecionada!.trim().isEmpty) {
      _mostrarMensagem(
        'Selecione a categoria da obra.',
        erro: true,
      );
      return;
    }

    if (_arquivoSelecionado == null) {
      _mostrarMensagem(
        'Selecione o documento PDF da obra.',
        erro: true,
      );
      return;
    }

    int? anoObra;

    final anoTexto = _anoController.text.trim();

    if (anoTexto.isNotEmpty) {
      anoObra = int.tryParse(anoTexto);

      if (anoObra == null) {
        _mostrarMensagem(
          'Digite um ano válido.',
          erro: true,
        );
        return;
      }
    }

    setState(() {
      _publicando = true;
    });

    try {
      await _publicacaoService.publicar(
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        autor: _autorController.text,
        categoria: _categoriaSelecionada!,
        arquivoPdf: _arquivoSelecionado!.bytes,
        nomeArquivo: _arquivoSelecionado!.nome,
        anoObra: anoObra,
      );

      if (!mounted) return;

      _mostrarMensagem(
        'Obra enviada com sucesso. '
            'A publicação ficará aguardando aprovação.',
      );

      _limparFormulario();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        _mensagemErro(e),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _publicando = false;
        });
      }
    }
  }

  void _limparFormulario() {
    _tituloController.clear();
    _descricaoController.clear();
    _autorController.clear();
    _anoController.clear();

    setState(() {
      _categoriaSelecionada = null;
      _arquivoSelecionado = null;
    });
  }

  String _mensagemErro(Object erro) {
    final mensagem = erro.toString();

    if (mensagem.startsWith('Exception: ')) {
      return mensagem.substring('Exception: '.length);
    }

    return mensagem;
  }

  void _mostrarMensagem(
      String mensagem, {
        bool erro = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    final larguraFormulario = largura > 800
        ? 700.0
        : largura - 32;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar obra'),
        centerTitle: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: larguraFormulario,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Publicar obra',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Preencha os dados da obra e envie o documento PDF. '
                            'A obra será analisada antes de ser publicada.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _tituloController,
                        textInputAction:
                        TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          hintText:
                          'Digite o título da obra',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          if (valor == null ||
                              valor.trim().isEmpty) {
                            return 'Informe o título da obra.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          hintText:
                          'Digite uma breve descrição da obra',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _autorController,
                        textInputAction:
                        TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Autor *',
                          hintText:
                          'Nome do autor da obra',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          if (valor == null ||
                              valor.trim().isEmpty) {
                            return 'Informe o autor da obra.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _categoriaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoria *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categorias.map(
                              (categoria) {
                            return DropdownMenuItem<String>(
                              value: categoria,
                              child: Text(categoria),
                            );
                          },
                        ).toList(),
                        onChanged: _publicando
                            ? null
                            : (valor) {
                          setState(() {
                            _categoriaSelecionada =
                                valor;
                          });
                        },
                        validator: (valor) {
                          if (valor == null ||
                              valor.trim().isEmpty) {
                            return 'Selecione uma categoria.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _anoController,
                        keyboardType:
                        TextInputType.number,
                        textInputAction:
                        TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ano da obra',
                          hintText: 'Ex.: 2025',
                          border: OutlineInputBorder(),
                        ),
                        validator: (valor) {
                          final texto =
                              valor?.trim() ?? '';

                          if (texto.isEmpty) {
                            return null;
                          }

                          final ano =
                          int.tryParse(texto);

                          if (ano == null) {
                            return 'Digite um ano válido.';
                          }

                          if (ano < 1000 ||
                              ano > 9999) {
                            return 'Digite um ano válido.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Documento PDF *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      InkWell(
                        onTap: _publicando
                            ? null
                            : _selecionarPdf,
                        borderRadius:
                        BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade400,
                            ),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                size: 32,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child:
                                _arquivoSelecionado ==
                                    null
                                    ? const Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      'Selecionar PDF',
                                      style:
                                      TextStyle(
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      'Tamanho máximo: 50 MB',
                                      style:
                                      TextStyle(
                                        color:
                                        Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )
                                    : Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      _arquivoSelecionado!
                                          .nome,
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      '${_arquivoSelecionado!.tamanhoMb.toStringAsFixed(2)} MB',
                                      style:
                                      const TextStyle(
                                        color:
                                        Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              const Icon(
                                Icons.upload_file,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                          _publicando ? null : _publicar,
                          child: _publicando
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Publicar obra',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
