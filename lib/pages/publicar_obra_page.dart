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

class _PublicarObraPageState
    extends State<PublicarObraPage> {
  final _formKey =
  GlobalKey<FormState>();

  final _tituloController =
  TextEditingController();

  final _descricaoController =
  TextEditingController();

  final _autorController =
  TextEditingController();

  final _anoController =
  TextEditingController();

  final ArquivoService _arquivoService =
      ArquivoService.instancia;

  final PublicacaoService _publicacaoService =
      PublicacaoService.instancia;

  String? _categoriaSelecionada;

  ArquivoSelecionado? _arquivoSelecionado;

  final List<ArquivoSelecionado>
  _imagensSelecionadas = [];

  bool _carregando = false;

  final List<String> _categorias = const [
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
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _autorController.dispose();
    _anoController.dispose();

    for (final secao in _secoes) {
      secao.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // SELECIONAR PDF
  // ============================================================

  Future<void> _selecionarArquivo() async {
    try {
      final arquivo =
      await _arquivoService.selecionarPdf();

      if (!mounted || arquivo == null) {
        return;
      }

      setState(() {
        _arquivoSelecionado = arquivo;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao selecionar arquivo: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SELECIONAR IMAGENS
  // ============================================================

  Future<void> _selecionarImagens() async {
    try {
      final imagens =
      await _arquivoService.selecionarImagens();

      if (!mounted || imagens.isEmpty) {
        return;
      }

      setState(() {
        for (final imagem in imagens) {
          final duplicada =
          _imagensSelecionadas.any(
                (existente) =>
            existente.nome == imagem.nome &&
                existente.tamanho == imagem.tamanho,
          );

          if (!duplicada) {
            _imagensSelecionadas.add(imagem);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao selecionar imagens: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // REMOVER IMAGEM
  // ============================================================

  void _removerImagem(int index) {
    if (_carregando) {
      return;
    }

    setState(() {
      _imagensSelecionadas.removeAt(index);
    });
  }

  // ============================================================
  // ADICIONAR SECÇÃO
  // ============================================================

  void _adicionarSecao() {
    setState(() {
      _secoes.add(
        _SecaoEditor(),
      );
    });
  }

  // ============================================================
  // REMOVER SECÇÃO
  // ============================================================

  void _removerSecao(int index) {
    if (_secoes.length <= 1) {
      return;
    }

    final secao =
    _secoes.removeAt(index);

    secao.dispose();

    setState(() {});
  }

  // ============================================================
  // PUBLICAR
  // ============================================================

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione a categoria da obra.',
          ),
        ),
      );

      return;
    }

    if (_arquivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione o arquivo PDF da obra.',
          ),
        ),
      );

      return;
    }

    final usuario =
        AuthService.instancia.usuarioAtual;

    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'É necessário estar autenticado para publicar.',
          ),
        ),
      );

      return;
    }

    final secoes =
    <Map<String, dynamic>>[];

    for (int i = 0;
    i < _secoes.length;
    i++) {
      final secao = _secoes[i];

      final titulo =
      secao.tituloController.text.trim();

      final conteudo =
      secao.conteudoController.text.trim();

      if (titulo.isEmpty &&
          conteudo.isEmpty) {
        continue;
      }

      if (titulo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Informe o título da secção ${i + 1}.',
            ),
          ),
        );

        return;
      }

      if (conteudo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Informe o conteúdo da secção "$titulo".',
            ),
          ),
        );

        return;
      }

      final nivel =
          int.tryParse(
            secao.nivelController.text.trim(),
          ) ??
              1;

      secoes.add({
        'titulo': titulo,
        'conteudo': conteudo,
        'ordem': secoes.length + 1,
        'nivel': nivel,
      });
    }

    if (secoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Adicione pelo menos uma secção da obra.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final ano = int.tryParse(
        _anoController.text.trim(),
      );

      await _publicacaoService.publicar(
        titulo:
        _tituloController.text.trim(),
        descricao:
        _descricaoController.text.trim(),
        autor:
        _autorController.text.trim(),
        categoria:
        _categoriaSelecionada!,
        anoObra: ano,
        arquivoPdf:
        _arquivoSelecionado!.bytes,
        nomeArquivo:
        _arquivoSelecionado!.nome,
        secoes: secoes,
        imagens:
        List<ArquivoSelecionado>.from(
          _imagensSelecionadas,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra enviada com sucesso para análise.',
          ),
        ),
      );

      _formKey.currentState!.reset();

      _tituloController.clear();
      _descricaoController.clear();
      _autorController.clear();
      _anoController.clear();

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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível publicar a obra: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // EDITOR DE SECÇÃO
  // ============================================================

  Widget _buildSecaoEditor(int index) {
    final secao =
    _secoes[index];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(10),
      ),
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
                    FontWeight.w600,
                  ),
                ),
              ),
              if (_secoes.length > 1)
                IconButton(
                  tooltip:
                  'Remover secção',
                  onPressed:
                  _carregando
                      ? null
                      : () =>
                      _removerSecao(
                        index,
                      ),
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller:
            secao.tituloController,
            enabled: !_carregando,
            textCapitalization:
            TextCapitalization.sentences,
            decoration:
            const InputDecoration(
              labelText:
              'Título da secção',
              hintText:
              'Ex.: Introdução',
              border:
              OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: secao.nivel,
            decoration:
            const InputDecoration(
              labelText:
              'Nível da secção',
              border:
              OutlineInputBorder(),
              helperText:
              '1 = secção principal, 2 = subseção, 3 = subsubseção.',
            ),
            items: const [
              DropdownMenuItem<int>(
                value: 1,
                child: Text(
                  'Nível 1 — Principal',
                ),
              ),
              DropdownMenuItem<int>(
                value: 2,
                child: Text(
                  'Nível 2 — Subsecção',
                ),
              ),
              DropdownMenuItem<int>(
                value: 3,
                child: Text(
                  'Nível 3 — Subsubsecção',
                ),
              ),
            ],
            onChanged:
            _carregando
                ? null
                : (valor) {
              if (valor == null) {
                return;
              }

              setState(() {
                secao.nivel =
                    valor;

                secao
                    .nivelController
                    .text =
                    valor.toString();
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller:
            secao.conteudoController,
            enabled: !_carregando,
            minLines: 8,
            maxLines: 20,
            keyboardType:
            TextInputType.multiline,
            textCapitalization:
            TextCapitalization.sentences,
            decoration:
            const InputDecoration(
              labelText:
              'Conteúdo da secção',
              hintText:
              'Escreva ou cole aqui o conteúdo desta secção...',
              alignLabelWithHint: true,
              border:
              OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGENS
  // ============================================================

  Widget _buildImagens() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Imagens da obra',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Opcional. Pode adicionar uma ou várias imagens. '
                'As imagens serão apresentadas depois do último conteúdo da obra.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed:
            _carregando
                ? null
                : _selecionarImagens,
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
            ),
            label: const Text(
              'Adicionar imagens',
            ),
          ),
          const SizedBox(height: 16),
          if (_imagensSelecionadas.isEmpty)
            const Text(
              'Nenhuma imagem selecionada.',
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(
                _imagensSelecionadas.length,
                    (index) {
                  final imagem =
                  _imagensSelecionadas[
                  index];

                  return SizedBox(
                    width: 180,
                    child: Container(
                      decoration:
                      BoxDecoration(
                        border: Border.all(
                          color: Colors
                              .grey
                              .shade300,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                      ),
                      padding:
                      const EdgeInsets
                          .all(8),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          ClipRRect(
                            borderRadius:
                            BorderRadius
                                .circular(
                              6,
                            ),
                            child:
                            Image.memory(
                              imagem.bytes,
                              width:
                              double.infinity,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            imagem.nome,
                            maxLines: 2,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            '${imagem.tamanhoMb.toStringAsFixed(2)} MB',
                            style:
                            TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey
                                  .shade700,
                            ),
                          ),
                          Align(
                            alignment:
                            Alignment
                                .centerRight,
                            child:
                            IconButton(
                              tooltip:
                              'Remover imagem',
                              onPressed:
                              _carregando
                                  ? null
                                  : () =>
                                  _removerImagem(
                                    index,
                                  ),
                              icon:
                              const Icon(
                                Icons
                                    .delete_outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text(
          'Publicar obra',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 800,
          ),
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'Publicar obra académica',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'Envie o seu trabalho para análise e posterior publicação na Obra Livre.',
                  ),
                  const SizedBox(
                    height: 32,
                  ),

                  TextFormField(
                    controller:
                    _tituloController,
                    enabled:
                    !_carregando,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Título',
                      border:
                      OutlineInputBorder(),
                    ),
                    validator:
                        (valor) {
                      if (valor ==
                          null ||
                          valor
                              .trim()
                              .isEmpty) {
                        return 'Informe o título.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextFormField(
                    controller:
                    _autorController,
                    enabled:
                    !_carregando,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Autor',
                      border:
                      OutlineInputBorder(),
                    ),
                    validator:
                        (valor) {
                      if (valor ==
                          null ||
                          valor
                              .trim()
                              .isEmpty) {
                        return 'Informe o autor.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  DropdownButtonFormField<
                      String>(
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
                    _categorias
                        .map(
                          (categoria) {
                        return DropdownMenuItem<
                            String>(
                          value:
                          categoria,
                          child:
                          Text(
                            categoria,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged:
                    _carregando
                        ? null
                        : (valor) {
                      setState(
                            () {
                          _categoriaSelecionada =
                              valor;
                        },
                      );
                    },
                    validator:
                        (valor) {
                      if (valor ==
                          null ||
                          valor
                              .isEmpty) {
                        return 'Selecione a categoria.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextFormField(
                    controller:
                    _anoController,
                    enabled:
                    !_carregando,
                    keyboardType:
                    TextInputType
                        .number,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Ano da obra',
                      border:
                      OutlineInputBorder(),
                    ),
                    validator:
                        (valor) {
                      if (valor ==
                          null ||
                          valor
                              .trim()
                              .isEmpty) {
                        return 'Informe o ano.';
                      }

                      if (int.tryParse(
                        valor
                            .trim(),
                      ) ==
                          null) {
                        return 'Informe um ano válido.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextFormField(
                    controller:
                    _descricaoController,
                    enabled:
                    !_carregando,
                    maxLines: 5,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Descrição',
                      alignLabelWithHint:
                      true,
                      border:
                      OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  const Text(
                    'Secções da obra',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Adicione as diferentes partes da obra. Cada secção terá o seu próprio título e conteúdo.',
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  ...List.generate(
                    _secoes.length,
                        (index) =>
                        _buildSecaoEditor(
                          index,
                        ),
                  ),

                  SizedBox(
                    width:
                    double.infinity,
                    child:
                    OutlinedButton.icon(
                      onPressed:
                      _carregando
                          ? null
                          : _adicionarSecao,
                      icon:
                      const Icon(
                        Icons
                            .add_circle_outline,
                      ),
                      label:
                      const Text(
                        'Adicionar secção',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  // ==================================================
                  // PDF
                  // ==================================================

                  Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.all(
                      20,
                    ),
                    decoration:
                    BoxDecoration(
                      border:
                      Border.all(
                        color: Colors
                            .grey
                            .shade300,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Text(
                          'Arquivo PDF',
                          style:
                          TextStyle(
                            fontSize:
                            16,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        if (_arquivoSelecionado ==
                            null)
                          const Text(
                            'Nenhum arquivo selecionado.',
                          )
                        else ...[
                          Text(
                            _arquivoSelecionado!
                                .nome,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .w500,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            '${_arquivoSelecionado!.tamanhoMb.toStringAsFixed(2)} MB',
                          ),
                        ],
                        const SizedBox(
                          height: 16,
                        ),
                        OutlinedButton.icon(
                          onPressed:
                          _carregando
                              ? null
                              : _selecionarArquivo,
                          icon:
                          const Icon(
                            Icons
                                .upload_file,
                          ),
                          label:
                          Text(
                            _arquivoSelecionado ==
                                null
                                ? 'Selecionar PDF'
                                : 'Alterar PDF',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // IMAGENS
                  // ==================================================

                  _buildImagens(),

                  const SizedBox(
                    height: 32,
                  ),

                  SizedBox(
                    width:
                    double.infinity,
                    height: 48,
                    child:
                    ElevatedButton(
                      onPressed:
                      _carregando
                          ? null
                          : _publicar,
                      child:
                      _carregando
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                        ),
                      )
                          : const Text(
                        'Enviar para análise',
                      ),
                    ),
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

// ================================================================
// MODELO LOCAL PARA EDIÇÃO DE SECÇÃO
// ================================================================

class _SecaoEditor {
  final TextEditingController
  tituloController =
  TextEditingController();

  final TextEditingController
  conteudoController =
  TextEditingController();

  final TextEditingController
  nivelController =
  TextEditingController(
    text: '1',
  );

  int nivel = 1;

  void dispose() {
    tituloController.dispose();
    conteudoController.dispose();
    nivelController.dispose();
  }
}
