import 'package:flutter/material.dart';

import '../repositories/solicitacoes_remocao_repository.dart';

class AdminSolicitacoesRemocaoPage extends StatefulWidget {
  const AdminSolicitacoesRemocaoPage({
    super.key,
  });

  @override
  State<AdminSolicitacoesRemocaoPage> createState() =>
      _AdminSolicitacoesRemocaoPageState();
}

class _AdminSolicitacoesRemocaoPageState
    extends State<AdminSolicitacoesRemocaoPage> {
  final SolicitacoesRemocaoRepository _repository =
      SolicitacoesRemocaoRepository.instancia;

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Map<String, dynamic>> _solicitacoes = [];

  bool _carregando = true;
  bool _processando = false;

  String _filtroStatus = 'pendente';

  @override
  void initState() {
    super.initState();
    _carregarSolicitacoes();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarSolicitacoes() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final dados = await _repository.obterSolicitacoes(
        status: _filtroStatus,
      );

      if (!mounted) return;

      setState(() {
        _solicitacoes = dados;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Não foi possível carregar as solicitações.',
        erro: true,
      );
    }
  }

  List<Map<String, dynamic>> get _solicitacoesFiltradas {
    final pesquisa =
    _pesquisaController.text.trim().toLowerCase();

    if (pesquisa.isEmpty) {
      return _solicitacoes;
    }

    return _solicitacoes.where((solicitacao) {
      final obra = solicitacao['obras'];
      final perfil = solicitacao['profiles'];

      final titulo = obra is Map
          ? (obra['titulo'] ?? '').toString().toLowerCase()
          : '';

      final autor = obra is Map
          ? (obra['autor'] ?? '').toString().toLowerCase()
          : '';

      final nome = perfil is Map
          ? (perfil['nome'] ?? '').toString().toLowerCase()
          : '';

      final email = perfil is Map
          ? (perfil['email'] ?? '').toString().toLowerCase()
          : '';

      return titulo.contains(pesquisa) ||
          autor.contains(pesquisa) ||
          nome.contains(pesquisa) ||
          email.contains(pesquisa);
    }).toList();
  }

  Future<void> _aprovar(
      Map<String, dynamic> solicitacao,
      ) async {
    if (_processando) return;

    final id = solicitacao['id']?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    final obra = solicitacao['obras'];

    final titulo = obra is Map
        ? (obra['titulo'] ?? 'esta obra').toString()
        : 'esta obra';

    final confirmar = await _confirmar(
      titulo: 'Aprovar remoção',
      mensagem:
      'Tem certeza que deseja aprovar a remoção de "$titulo"?\n\n'
          'A obra será removida das publicações.',
      textoConfirmar: 'Aprovar',
    );

    if (!confirmar) return;

    setState(() {
      _processando = true;
    });

    try {
      await _repository.aprovarSolicitacao(id);

      if (!mounted) return;

      _mostrarMensagem(
        'Solicitação aprovada e obra removida.',
      );

      await _carregarSolicitacoes();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        _mensagemErro(e),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  Future<void> _rejeitar(
      Map<String, dynamic> solicitacao,
      ) async {
    if (_processando) return;

    final id = solicitacao['id']?.toString();

    if (id == null || id.isEmpty) {
      return;
    }

    final observacaoController =
    TextEditingController();

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Rejeitar solicitação',
          ),
          content: TextField(
            controller: observacaoController,
            maxLines: 4,
            textCapitalization:
            TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Observação',
              hintText:
              'Informe o motivo da rejeição',
              border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(6),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final texto =
                observacaoController.text.trim();

                if (texto.isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  texto,
                );
              },
              child: const Text('Rejeitar'),
            ),
          ],
        );
      },
    );

    observacaoController.dispose();

    if (resultado == null ||
        resultado.trim().isEmpty) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await _repository.rejeitarSolicitacao(
        id,
        observacao: resultado.trim(),
      );

      if (!mounted) return;

      _mostrarMensagem(
        'Solicitação rejeitada com sucesso.',
      );

      // Recarrega diretamente o filtro atual.
      // Como estamos em "pendente", o pedido
      // rejeitado desaparece imediatamente.
      await _carregarSolicitacoes();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        _mensagemErro(e),
        erro: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  Future<bool> _confirmar({
    required String titulo,
    required String mensagem,
    required String textoConfirmar,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  String _mensagemErro(Object erro) {
    final texto = erro.toString();

    if (texto.startsWith('Exception: ')) {
      return texto.substring(11);
    }

    return 'Não foi possível concluir a operação.';
  }

  void _mostrarMensagem(
      String mensagem, {
        bool erro = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _textoData(dynamic valor) {
    if (valor == null) {
      return '';
    }

    final data = DateTime.tryParse(
      valor.toString(),
    );

    if (data == null) {
      return valor.toString();
    }

    final local = data.toLocal();

    final dia =
    local.day.toString().padLeft(2, '0');

    final mes =
    local.month.toString().padLeft(2, '0');

    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  String _statusTexto(String status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';

      case 'aprovada':
        return 'Aprovada';

      case 'rejeitada':
        return 'Rejeitada';

      default:
        return status;
    }
  }

  Color _statusCor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;

      case 'aprovada':
        return Colors.green;

      case 'rejeitada':
        return Colors.red;

      default:
        return Colors.black54;
    }
  }

  Widget _buildObservacao(
      Map<String, dynamic> solicitacao,
      ) {
    final observacao =
    (solicitacao['observacao_admin'] ?? '')
        .toString()
        .trim();

    if (observacao.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F2),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Observação do administrador',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(observacao),
        ],
      ),
    );
  }

  void _selecionarFiltro(String status) {
    if (_filtroStatus == status) {
      return;
    }

    setState(() {
      _filtroStatus = status;
    });

    _carregarSolicitacoes();
  }

  @override
  Widget build(BuildContext context) {
    final solicitacoes =
        _solicitacoesFiltradas;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Solicitações de remoção',
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando
                ? null
                : _carregarSolicitacoes,
            icon:
            const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding:
            const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16,
            ),
            child: Column(
              children: [
                TextField(
                  controller:
                  _pesquisaController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration:
                  InputDecoration(
                    hintText:
                    'Pesquisar obra, autor ou usuário',
                    prefixIcon:
                    const Icon(
                      Icons.search,
                    ),
                    suffixIcon:
                    _pesquisaController
                        .text
                        .isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _pesquisaController
                            .clear();
                        setState(() {});
                      },
                      icon:
                      const Icon(
                        Icons.clear,
                      ),
                    )
                        : null,
                    filled: true,
                    fillColor:
                    const Color(
                      0xFFF2F2F2,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        6,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment:
                  Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label:
                        const Text(
                          'Pendentes',
                        ),
                        selected:
                        _filtroStatus ==
                            'pendente',
                        onSelected: (_) {
                          _selecionarFiltro(
                            'pendente',
                          );
                        },
                      ),
                      ChoiceChip(
                        label:
                        const Text(
                          'Aprovadas',
                        ),
                        selected:
                        _filtroStatus ==
                            'aprovada',
                        onSelected: (_) {
                          _selecionarFiltro(
                            'aprovada',
                          );
                        },
                      ),
                      ChoiceChip(
                        label:
                        const Text(
                          'Rejeitadas',
                        ),
                        selected:
                        _filtroStatus ==
                            'rejeitada',
                        onSelected: (_) {
                          _selecionarFiltro(
                            'rejeitada',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : solicitacoes.isEmpty
                ? const Center(
              child: Text(
                'Nenhuma solicitação encontrada.',
                style: TextStyle(
                  color:
                  Colors.black54,
                  fontSize: 15,
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh:
              _carregarSolicitacoes,
              child:
              ListView.separated(
                padding:
                const EdgeInsets
                    .all(20),
                itemCount:
                solicitacoes.length,
                separatorBuilder:
                    (_, __) =>
                const SizedBox(
                  height: 12,
                ),
                itemBuilder:
                    (context, index) {
                  final solicitacao =
                  solicitacoes[
                  index];

                  final obra =
                  solicitacao[
                  'obras']
                  is Map
                      ? Map<String,
                      dynamic>.from(
                    solicitacao[
                    'obras'],
                  )
                      : <String,
                      dynamic>{};

                  final perfil =
                  solicitacao[
                  'profiles']
                  is Map
                      ? Map<String,
                      dynamic>.from(
                    solicitacao[
                    'profiles'],
                  )
                      : <String,
                      dynamic>{};

                  final titulo =
                  (obra['titulo'] ??
                      'Obra sem título')
                      .toString();

                  final autor =
                  (obra['autor'] ??
                      'Autor não informado')
                      .toString();

                  final nome =
                  (perfil['nome'] ??
                      'Usuário')
                      .toString();

                  final email =
                  (perfil['email'] ??
                      '')
                      .toString();

                  final motivo =
                  (solicitacao[
                  'motivo'] ??
                      '')
                      .toString();

                  final status =
                  (solicitacao[
                  'status'] ??
                      '')
                      .toString();

                  final data =
                  _textoData(
                    solicitacao[
                    'created_at'],
                  );

                  return Card(
                    elevation: 0,
                    color:
                    Colors.white,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        8,
                      ),
                      side:
                      const BorderSide(
                        color:
                        Color(
                          0xFFE5E5E5,
                        ),
                      ),
                    ),
                    child:
                    Padding(
                      padding:
                      const EdgeInsets
                          .all(18),
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const Icon(
                                Icons
                                    .description_outlined,
                                color:
                                Colors.black54,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Expanded(
                                child:
                                Text(
                                  titulo,
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    17,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              9,
                              vertical:
                              5,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              _statusCor(
                                status,
                              ).withValues(
                                alpha:
                                0.10,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),
                            ),
                            child:
                            Text(
                              _statusTexto(
                                status,
                              ),
                              style:
                              TextStyle(
                                color:
                                _statusCor(
                                  status,
                                ),
                                fontSize:
                                12,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Autor: $autor',
                            style:
                            const TextStyle(
                              color:
                              Colors.black54,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Solicitado por: $nome',
                            style:
                            const TextStyle(
                              color:
                              Colors.black54,
                            ),
                          ),
                          if (email
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              email,
                              style:
                              const TextStyle(
                                color:
                                Colors.black54,
                                fontSize:
                                13,
                              ),
                            ),
                          ],
                          const SizedBox(
                            height: 12,
                          ),
                          Container(
                            width:
                            double.infinity,
                            padding:
                            const EdgeInsets
                                .all(12),
                            decoration:
                            BoxDecoration(
                              color:
                              const Color(
                                0xFFF6F6F6,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                6,
                              ),
                            ),
                            child:
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                const Text(
                                  'Motivo da remoção',
                                  style:
                                  TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .w600,
                                    fontSize:
                                    13,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  motivo.isEmpty
                                      ? 'Nenhum motivo informado.'
                                      : motivo,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Solicitado em: $data',
                            style:
                            const TextStyle(
                              color:
                              Colors.black54,
                              fontSize:
                              12,
                            ),
                          ),
                          if (status ==
                              'rejeitada') ...[
                            const SizedBox(
                              height: 12,
                            ),
                            _buildObservacao(
                              solicitacao,
                            ),
                          ],
                          if (status ==
                              'pendente') ...[
                            const SizedBox(
                              height: 16,
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .end,
                              children: [
                                OutlinedButton(
                                  onPressed:
                                  _processando
                                      ? null
                                      : () =>
                                      _rejeitar(
                                        solicitacao,
                                      ),
                                  child:
                                  const Text(
                                    'Rejeitar',
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                FilledButton(
                                  onPressed:
                                  _processando
                                      ? null
                                      : () =>
                                      _aprovar(
                                        solicitacao,
                                      ),
                                  child:
                                  const Text(
                                    'Aprovar',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

