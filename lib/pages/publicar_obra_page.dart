import 'package:flutter/material.dart';

import '../services/arquivo_service.dart';
import '../services/auth_service.dart';
import '../services/publicacao_service.dart';

class PublicarObraPage extends StatefulWidget {
  const PublicarObraPage({
    super.key,
  });

  @override
  State<PublicarObraPage> createState() => _PublicarObraPageState();
}

class _PublicarObraPageState extends State<PublicarObraPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _autorController = TextEditingController();
  final _anoController = TextEditingController();

  final ArquivoService _arquivoService =
      ArquivoService.instancia;

  final PublicacaoService _publicacaoService =
      PublicacaoService.instancia;

  String? _categoriaSelecionada;

  ArquivoSelecionado? _arquivoSelecionado;

  bool _carregando = false;

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

    setState(() {
      _carregando = true;
    });

    try {
      final ano = int.tryParse(
        _anoController.text.trim(),
      );

      await _publicacaoService.publicar(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        autor: _autorController.text.trim(),
        categoria: _categoriaSelecionada!,
        anoObra: ano,
        arquivoPdf: _arquivoSelecionado!.bytes,
        nomeArquivo: _arquivoSelecionado!.nome,
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

      setState(() {
        _categoriaSelecionada = null;
        _arquivoSelecionado = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar obra'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Publicar obra académica',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Envie o seu trabalho para análise e posterior publicação na Obra Livre.',
                  ),

                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return 'Informe o título.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _autorController,
                    decoration: const InputDecoration(
                      labelText: 'Autor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return 'Informe o autor.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _categoriaSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: _categorias.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: _carregando
                        ? null
                        : (valor) {
                      setState(() {
                        _categoriaSelecionada =
                            valor;
                      });
                    },
                    validator: (valor) {
                      if (valor == null ||
                          valor.isEmpty) {
                        return 'Selecione a categoria.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _anoController,
                    keyboardType:
                    TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ano da obra',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null ||
                          valor.trim().isEmpty) {
                        return 'Informe o ano.';
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

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _descricaoController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
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
                          'Arquivo PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (_arquivoSelecionado == null)
                          const Text(
                            'Nenhum arquivo selecionado.',
                          )
                        else ...[
                          Text(
                            _arquivoSelecionado!.nome,
                            style: const TextStyle(
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${_arquivoSelecionado!.tamanhoMb.toStringAsFixed(2)} MB',
                          ),
                        ],

                        const SizedBox(height: 16),

                        OutlinedButton.icon(
                          onPressed: _carregando
                              ? null
                              : _selecionarArquivo,
                          icon: const Icon(
                            Icons.upload_file,
                          ),
                          label: Text(
                            _arquivoSelecionado ==
                                null
                                ? 'Selecionar PDF'
                                : 'Alterar PDF',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                      _carregando ? null : _publicar,
                      child: _carregando
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
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

