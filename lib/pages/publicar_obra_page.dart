import 'package:flutter/material.dart';

import '../services/arquivo_service.dart';
import '../services/auth_service.dart';
import '../services/publicacao_service.dart';

class PublicarObraPage extends StatefulWidget {
  const PublicarObraPage({super.key});

  @override
  State<PublicarObraPage> createState() => _PublicarObraPageState();
}

class _PublicarObraPageState extends State<PublicarObraPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _autorController = TextEditingController();
  final _anoController = TextEditingController();

  final _arquivoService = ArquivoService.instancia;
  final _publicacaoService = PublicacaoService.instancia;

  String? _categoriaSelecionada;

  ArquivoSelecionado? _arquivoSelecionado;

  final List<_ImagemEditor> _imagensSelecionadas = [];

  bool _carregando = false;

  static const int _maxPalavrasDescricao = 30;
  static const int _maxPalavrasConteudo = 2000;

  final List<String> _categorias = [
    'Tese de Doutoramento',
    'Dissertação de Mestrado',
    'Monografia',
    'Artigos Científicos',
    'Comunicações Científicas',
    'Posters',
    'Resumos',
    'Relatórios Académicos',
    'Trabalhos Académicos',
  ];

  final List<_SecaoEditor> _secoes = [
    _SecaoEditor(),
  ];

  @override
  void initState() {
    super.initState();

    _descricaoController.addListener(_limitarDescricao);
  }

  @override
  void dispose() {
    _descricaoController.removeListener(_limitarDescricao);

    _tituloController.dispose();
    _descricaoController.dispose();
    _autorController.dispose();
    _anoController.dispose();

    for (final imagem in _imagensSelecionadas) {
      imagem.dispose();
    }

    for (final secao in _secoes) {
      secao.dispose();
    }

    super.dispose();
  }

  int _contarPalavras(String texto) {
    final textoLimpo = texto.trim();

    if (textoLimpo.isEmpty) {
      return 0;
    }

    return textoLimpo.split(RegExp(r'\s+')).length;
  }

  void _limitarDescricao() {
    final texto = _descricaoController.text;

    if (texto.trim().isEmpty) {
      return;
    }

    if (_contarPalavras(texto) <= _maxPalavrasDescricao) {
      return;
    }

    final palavras = texto.trim().split(RegExp(r'\s+'));

    final textoLimitado = palavras
        .take(_maxPalavrasDescricao)
        .join(' ');

    _descricaoController.value = TextEditingValue(
      text: textoLimitado,
      selection: TextSelection.collapsed(
        offset: textoLimitado.length,
      ),
    );

    _mostrarMensagem(
      'A descrição pode ter no máximo 30 palavras.',
      erro: true,
    );
  }

  void _limitarConteudoSecao(
      _SecaoEditor secao,
      ) {
    final texto = secao.conteudoController.text;

    if (texto.trim().isEmpty) {
      return;
    }

    if (_contarPalavras(texto) <= _maxPalavrasConteudo) {
      return;
    }

    final palavras = texto.trim().split(RegExp(r'\s+'));

    final textoLimitado = palavras
        .take(_maxPalavrasConteudo)
        .join(' ');

    secao.conteudoController.value = TextEditingValue(
      text: textoLimitado,
      selection: TextSelection.collapsed(
        offset: textoLimitado.length,
      ),
    );

    _mostrarMensagem(
      'O conteúdo de cada secção pode ter no máximo 2000 palavras.',
      erro: true,
    );
  }

  Future<void> _selecionarArquivo() async {
    try {
      final arquivo = await _arquivoService.selecionarPdf();

      if (arquivo == null) {
        return;
      }

      setState(() {
        _arquivoSelecionado = arquivo;
      });
    } catch (e) {
      _mostrarMensagem(
        'Erro ao selecionar o PDF: $e',
        erro: true,
      );
    }
  }

  Future<void> _selecionarImagens() async {
    try {
      final imagens = await _arquivoService.selecionarImagens();

      if (imagens.isEmpty) {
        return;
      }

      setState(() {
        for (final imagem in imagens) {
          final existe = _imagensSelecionadas.any(
                (item) =>
            item.arquivo.nome == imagem.nome &&
                item.arquivo.tamanho == imagem.tamanho,
          );

          if (!existe) {
            _imagensSelecionadas.add(
              _ImagemEditor(
                arquivo: imagem,
              ),
            );
          }
        }
      });
    } catch (e) {
      _mostrarMensagem(
        'Erro ao selecionar imagens: $e',
        erro: true,
      );
    }
  }

  void _removerImagem(int index) {
    if (index < 0 ||
        index >= _imagensSelecionadas.length) {
      return;
    }

    final imagem = _imagensSelecionadas[index];

    imagem.dispose();

    setState(() {
      _imagensSelecionadas.removeAt(index);
    });
  }

  void _adicionarSecao() {
    setState(() {
      _secoes.add(
        _SecaoEditor(),
      );
    });
  }

  void _removerSecao(int index) {
    if (_secoes.length <= 1) {
      return;
    }

    if (index < 0 ||
        index >= _secoes.length) {
      return;
    }

    final secao = _secoes[index];

    secao.dispose();

    setState(() {
      _secoes.removeAt(index);
    });
  }

  void _cancelar() {
    if (_carregando) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _publicar() async {
    if (_carregando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSelecionada == null) {
      _mostrarMensagem(
        'Selecione a categoria da obra.',
        erro: true,
      );
      return;
    }

    if (_arquivoSelecionado == null) {
      _mostrarMensagem(
        'Selecione o ficheiro PDF da obra.',
        erro: true,
      );
      return;
    }

    final utilizador =
        AuthService.instancia.usuarioAtual;

    if (utilizador == null) {
      _mostrarMensagem(
        'É necessário estar autenticado para publicar uma obra.',
        erro: true,
      );
      return;
    }

    final descricao =
    _descricaoController.text.trim();

    if (_contarPalavras(descricao) >
        _maxPalavrasDescricao) {
      _mostrarMensagem(
        'A descrição pode ter no máximo 30 palavras.',
        erro: true,
      );
      return;
    }

    final List<Map<String, dynamic>> secoes = [];

    for (int i = 0; i < _secoes.length; i++) {
      final secao = _secoes[i];

      final titulo =
      secao.tituloController.text.trim();

      final conteudo =
      secao.conteudoController.text.trim();

      if (_contarPalavras(conteudo) >
          _maxPalavrasConteudo) {
        _mostrarMensagem(
          'A Secção ${i + 1} ultrapassa o limite de 2000 palavras.',
          erro: true,
        );
        return;
      }

      if (titulo.isEmpty &&
          conteudo.isEmpty) {
        continue;
      }

      secoes.add({
        'titulo': titulo,
        'conteudo': conteudo,
        'ordem': i + 1,
        'nivel': secao.nivel,
      });
    }

    if (secoes.isEmpty) {
      _mostrarMensagem(
        'Adicione pelo menos uma secção com conteúdo.',
        erro: true,
      );
      return;
    }

    final List<Map<String, dynamic>> imagens = [];

    for (final imagem in _imagensSelecionadas) {
      final paragrafoTexto =
      imagem.paragrafoOrdemController.text.trim();

      int? paragrafoOrdem;

      if (paragrafoTexto.isNotEmpty) {
        paragrafoOrdem =
            int.tryParse(paragrafoTexto);

        if (paragrafoOrdem == null ||
            paragrafoOrdem < 1) {
          _mostrarMensagem(
            'A ordem do parágrafo da imagem "${imagem.arquivo.nome}" é inválida.',
            erro: true,
          );
          return;
        }
      }

      imagens.add({
        'arquivo': imagem.arquivo,
        'legenda':
        imagem.legendaController.text.trim(),
        'fonte':
        imagem.fonteController.text.trim(),
        'paragrafoOrdem': paragrafoOrdem,
      });
    }

    final anoTexto =
    _anoController.text.trim();

    int? ano;

    if (anoTexto.isNotEmpty) {
      ano = int.tryParse(anoTexto);
    }

    setState(() {
      _carregando = true;
    });

    try {
      await _publicacaoService.publicar(
        titulo: _tituloController.text.trim(),
        descricao: descricao,
        autor: _autorController.text.trim(),
        categoria: _categoriaSelecionada!,
        anoObra: ano,
        arquivoPdf: _arquivoSelecionado!.bytes,
        nomeArquivo: _arquivoSelecionado!.nome,
        secoes: secoes,
        imagens: imagens,
      );

      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Obra enviada com sucesso para análise.',
      );

      _tituloController.clear();
      _descricaoController.clear();
      _autorController.clear();
      _anoController.clear();

      for (final imagem in _imagensSelecionadas) {
        imagem.dispose();
      }

      for (final secao in _secoes) {
        secao.dispose();
      }

      setState(() {
        _categoriaSelecionada = null;
        _arquivoSelecionado = null;

        _imagensSelecionadas.clear();

        _secoes.clear();

        _secoes.add(
          _SecaoEditor(),
        );
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mostrarMensagem(
        'Erro ao publicar a obra: $e',
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Widget _buildSecaoEditor(
      BuildContext context,
      int index,
      ) {
    final secao = _secoes[index];

    final quantidadePalavras =
    _contarPalavras(
      secao.conteudoController.text,
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Secção ${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
                if (_secoes.length > 1)
                  IconButton(
                    tooltip:
                    'Remover secção',
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                    onPressed: () {
                      _removerSecao(index);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
              secao.tituloController,
              decoration:
              const InputDecoration(
                labelText:
                'Título da secção',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: secao.nivel,
              decoration:
              const InputDecoration(
                labelText:
                'Nível da secção',
                border:
                OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text(
                    'Nível 1',
                  ),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(
                    'Nível 2',
                  ),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(
                    'Nível 3',
                  ),
                ),
              ],
              onChanged: (valor) {
                if (valor == null) {
                  return;
                }

                setState(() {
                  secao.nivel = valor;
                });
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
              secao.conteudoController,
              maxLines: 8,
              decoration:
              InputDecoration(
                labelText:
                'Conteúdo',
                alignLabelWithHint: true,
                border:
                const OutlineInputBorder(),
                helperText:
                '$quantidadePalavras/$_maxPalavrasConteudo palavras',
                helperStyle:
                TextStyle(
                  color:
                  quantidadePalavras >=
                      _maxPalavrasConteudo
                      ? Colors.red
                      : Colors.grey,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
              onChanged: (_) {
                _limitarConteudoSecao(
                  secao,
                );

                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagens() {
    if (_imagensSelecionadas.isEmpty) {
      return const Text(
        'Nenhuma imagem selecionada.',
        style: TextStyle(
          color: Colors.grey,
        ),
      );
    }

    return Column(
      children: List.generate(
        _imagensSelecionadas.length,
            (index) {
          final imagem =
          _imagensSelecionadas[index];

          return Card(
            margin:
            const EdgeInsets.only(
              bottom: 16,
            ),
            child: Padding(
              padding:
              const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          imagem.arquivo.nome,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip:
                        'Remover imagem',
                        icon: const Icon(
                          Icons
                              .delete_outline,
                        ),
                        onPressed: () {
                          _removerImagem(
                            index,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                        8,
                      ),
                      child:
                      Image.memory(
                        imagem.arquivo.bytes,
                        height: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (
                            context,
                            error,
                            stackTrace,
                            ) {
                          return Container(
                            height: 180,
                            width:
                            double.infinity,
                            alignment:
                            Alignment.center,
                            color: Colors
                                .grey
                                .shade200,
                            child:
                            const Icon(
                              Icons
                                  .broken_image_outlined,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller:
                    imagem
                        .legendaController,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Legenda da imagem',
                      hintText:
                      'Ex.: Figura 1 — Localização do Município de Nampula',
                      border:
                      OutlineInputBorder(),
                      prefixIcon:
                      Icon(
                        Icons
                            .description_outlined,
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                    imagem.fonteController,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Fonte da imagem',
                      hintText:
                      'Ex.: Autor, 2026 / Google Earth / INE',
                      border:
                      OutlineInputBorder(),
                      prefixIcon:
                      Icon(
                        Icons
                            .source_outlined,
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                    imagem
                        .paragrafoOrdemController,
                    keyboardType:
                    TextInputType.number,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Parágrafo onde a imagem aparece',
                      hintText: 'Ex.: 3',
                      helperText:
                      'Informe o número do parágrafo após o qual a imagem deve aparecer.',
                      border:
                      OutlineInputBorder(),
                      prefixIcon:
                      Icon(
                        Icons
                            .format_list_numbered,
                      ),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return null;
                      }

                      final numero =
                      int.tryParse(
                        valor.trim(),
                      );

                      if (numero == null ||
                          numero < 1) {
                        return 'Informe um número de parágrafo válido.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarMensagem(
      String mensagem, {
        bool erro = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor:
        erro ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Publicar Obra',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 900,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller:
                    _tituloController,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Título da obra',
                      border:
                      OutlineInputBorder(),
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
                    controller:
                    _autorController,
                    decoration:
                    const InputDecoration(
                      labelText: 'Autor',
                      border:
                      OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return 'Informe o autor.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value:
                    _categoriaSelecionada,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Categoria',
                      border:
                      OutlineInputBorder(),
                    ),
                    items:
                    _categorias.map(
                          (categoria) {
                        return DropdownMenuItem<
                            String>(
                          value:
                          categoria,
                          child:
                          Text(categoria),
                        );
                      },
                    ).toList(),
                    onChanged: (valor) {
                      setState(() {
                        _categoriaSelecionada =
                            valor;
                      });
                    },
                    validator: (valor) {
                      if (valor == null ||
                          valor.isEmpty) {
                        return 'Selecione uma categoria.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller:
                    _anoController,
                    keyboardType:
                    TextInputType.number,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Ano da obra',
                      border:
                      OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return null;
                      }

                      if (int.tryParse(
                        valor.trim(),
                      ) ==
                          null) {
                        return 'Informe um ano válido.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller:
                    _descricaoController,
                    maxLines: 5,
                    decoration:
                    InputDecoration(
                      labelText:
                      'Descrição',
                      alignLabelWithHint:
                      true,
                      border:
                      const OutlineInputBorder(),
                      helperText:
                      '${_contarPalavras(_descricaoController.text)}/$_maxPalavrasDescricao palavras',
                      helperStyle:
                      TextStyle(
                        color:
                        _contarPalavras(
                          _descricaoController
                              .text,
                        ) >=
                            _maxPalavrasDescricao
                            ? Colors.red
                            : Colors.grey,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Conteúdo da obra',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...List.generate(
                    _secoes.length,
                        (index) =>
                        _buildSecaoEditor(
                          context,
                          index,
                        ),
                  ),

                  OutlinedButton.icon(
                    onPressed:
                    _adicionarSecao,
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Adicionar secção',
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Documento PDF',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .picture_as_pdf,
                            size: 40,
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Text(
                              _arquivoSelecionado
                                  ?.nome ??
                                  'Nenhum PDF selecionado',
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed:
                            _selecionarArquivo,
                            icon: const Icon(
                              Icons
                                  .upload_file,
                            ),
                            label:
                            const Text(
                              'Selecionar PDF',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Imagens',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Adicione imagens e informe a legenda, a fonte e o parágrafo onde cada imagem deverá aparecer.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed:
                    _selecionarImagens,
                    icon: const Icon(
                      Icons
                          .add_photo_alternate_outlined,
                    ),
                    label: const Text(
                      'Adicionar imagens',
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildImagens(),

                  const SizedBox(height: 32),

                  // ==================================================
                  // BOTÕES CANCELAR E ENVIAR
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed:
                          _carregando
                              ? null
                              : _cancelar,
                          child:
                          const Text(
                            'Cancelar',
                          ),
                          style:
                          OutlinedButton
                              .styleFrom(
                            backgroundColor:
                            Colors
                                .grey
                                .shade200,
                            foregroundColor:
                            Colors
                                .black87,
                            side:
                            BorderSide(
                              color: Colors
                                  .grey
                                  .shade400,
                            ),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                          _carregando
                              ? null
                              : _publicar,
                          child: _carregando
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2,
                            ),
                          )
                              : const Text(
                            'Enviar',
                          ),
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xFF1565C0,
                            ),
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                10,
                              ),
                            ),
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// EDITOR DE IMAGEM
// ==================================================================

class _ImagemEditor {
  _ImagemEditor({
    required this.arquivo,
  });

  final ArquivoSelecionado arquivo;

  final TextEditingController
  legendaController =
  TextEditingController();

  final TextEditingController
  fonteController =
  TextEditingController();

  final TextEditingController
  paragrafoOrdemController =
  TextEditingController();

  void dispose() {
    legendaController.dispose();
    fonteController.dispose();
    paragrafoOrdemController.dispose();
  }
}

// ==================================================================
// EDITOR DE SECÇÃO
// ==================================================================

class _SecaoEditor {
  _SecaoEditor();

  final TextEditingController
  tituloController =
  TextEditingController();

  final TextEditingController
  conteudoController =
  TextEditingController();

  int nivel = 1;

  void dispose() {
    tituloController.dispose();
    conteudoController.dispose();
  }
}

