

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comentario.dart';
import '../repositories/comentarios_repository.dart';

class ComentariosSection extends StatefulWidget {
  final String obraId;

  const ComentariosSection({
    super.key,
    required this.obraId,
  });

  @override
  State<ComentariosSection> createState() =>
      _ComentariosSectionState();
}

class _ComentariosSectionState
    extends State<ComentariosSection> {
  final ComentariosRepository _repository =
      ComentariosRepository.instancia;

  final TextEditingController
  _comentarioController =
  TextEditingController();

  List<Comentario> _comentarios = [];

  /// Guarda os nomes dos utilizadores autenticados.
  final Map<String, String> _nomesUtilizadores = {};

  bool _carregando = true;
  bool _enviando = false;
  bool _ehAdmin = false;

  String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();

    _carregarEstadoAdmin();
    _carregarComentarios();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  /// Verifica se o utilizador atual é administrador.
  Future<void> _carregarEstadoAdmin() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
      });

      return;
    }

    try {
      final perfil = await Supabase
          .instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _ehAdmin =
            perfil?['role']?.toString() == 'admin';
      });
    } catch (e) {
      debugPrint(
        'COMENTARIOS: erro ao verificar administrador: $e',
      );

      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
      });
    }
  }

  Future<void> _carregarComentarios() async {
    if (mounted) {
      setState(() {
        _carregando = true;
      });
    }

    try {
      final comentarios =
      await _repository.obterComentarios(
        widget.obraId,
      );

      await _carregarNomesUtilizadores(
        comentarios,
      );

      if (!mounted) return;

      setState(() {
        _comentarios = comentarios;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      debugPrint(
        'COMENTARIOS: erro ao carregar: $e',
      );

      _mostrarMensagem(
        'Não foi possível carregar os comentários.',
      );
    }
  }

  /// Obtém os nomes através da tabela profiles.
  Future<void> _carregarNomesUtilizadores(
      List<Comentario> comentarios,
      ) async {
    final ids = comentarios
        .map(
          (comentario) => comentario.userId,
    )
        .whereType<String>()
        .where(
          (id) => id.trim().isNotEmpty,
    )
        .toSet()
        .toList();

    if (ids.isEmpty) return;

    try {
      final resposta = await Supabase
          .instance.client
          .from('perfis_publicos')
          .select('id, nome')
          .inFilter('id', ids);

      for (final perfil in resposta) {
        final id =
        perfil['id']?.toString();

        final nome =
        perfil['nome']?.toString().trim();

        if (id != null &&
            id.isNotEmpty &&
            nome != null &&
            nome.isNotEmpty) {
          _nomesUtilizadores[id] = nome;
        }
      }
    } catch (e) {
      debugPrint(
        'COMENTARIOS: erro ao carregar nomes: $e',
      );
    }
  }

  /// Define o nome apresentado no comentário.
  ///
  /// Visitante:
  /// user_id NULL -> Visitante
  ///
  /// Utilizador autenticado:
  /// procura primeiro em profiles.nome.
  ///
  /// Se for o utilizador atual:
  /// tenta também userMetadata['nome'].
  String _obterNomeUtilizador(
      Comentario comentario,
      ) {
    // Somente user_id NULL é visitante.
    if (comentario.userId == null) {
      return 'Visitante';
    }

    final id = comentario.userId!;

    // Primeiro tenta o nome guardado no profiles.
    final nome =
    _nomesUtilizadores[id];

    if (nome != null &&
        nome.trim().isNotEmpty) {
      return nome.trim();
    }

    // Se for o utilizador atualmente autenticado,
    // tenta obter o nome dos metadados.
    if (id == _userId) {
      final metadata =
          Supabase.instance.client.auth.currentUser
              ?.userMetadata;

      final nomeAtual =
      metadata?['nome']?.toString().trim();

      if (nomeAtual != null &&
          nomeAtual.isNotEmpty) {
        return nomeAtual;
      }
    }

    // IMPORTANTE:
    // um comentário que possui user_id
    // nunca deve ser apresentado como visitante.
    return 'Utilizador';
  }

  String _obterInicialNome(
      Comentario comentario,
      ) {
    final nome =
    _obterNomeUtilizador(comentario);

    if (nome.trim().isEmpty) {
      return 'U';
    }

    return nome
        .trim()
        .substring(0, 1)
        .toUpperCase();
  }

  Future<void> _enviarComentario() async {
    final texto =
    _comentarioController.text.trim();

    if (texto.isEmpty) {
      _mostrarMensagem(
        'Escreva um comentário.',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _enviando = true;
      });
    }

    try {
      final novoComentario =
      await _repository.criarComentario(
        obraId: widget.obraId,
        comentario: texto,
      );

      if (novoComentario.userId != null &&
          !_nomesUtilizadores.containsKey(
            novoComentario.userId,
          )) {
        await _carregarNomesUtilizadores(
          [novoComentario],
        );
      }

      if (!mounted) return;

      setState(() {
        _comentarios.add(novoComentario);
        _comentarioController.clear();
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _enviando = false;
      });

      debugPrint(
        'COMENTARIOS: erro ao publicar: $e',
      );

      _mostrarMensagem(
        'Não foi possível publicar o comentário.',
      );
    }
  }

  Future<void> _editarComentario(
      Comentario comentario,
      ) async {
    final controller =
    TextEditingController(
      text: comentario.comentario,
    );

    final novoTexto =
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Editar comentário',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            decoration:
            const InputDecoration(
              hintText:
              'Escreva o seu comentário...',
              border:
              OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                final texto =
                controller.text.trim();

                if (texto.isNotEmpty) {
                  Navigator.pop(
                    context,
                    texto,
                  );
                }
              },
              child: const Text(
                'Guardar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (novoTexto == null ||
        novoTexto.trim().isEmpty ||
        novoTexto.trim() ==
            comentario.comentario) {
      return;
    }

    try {
      final atualizado =
      await _repository.atualizarComentario(
        comentarioId: comentario.id,
        comentario: novoTexto,
      );

      if (!mounted) return;

      setState(() {
        final indice =
        _comentarios.indexWhere(
              (item) =>
          item.id == comentario.id,
        );

        if (indice != -1) {
          _comentarios[indice] =
              atualizado;
        }
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'COMENTARIOS: erro ao editar: $e',
      );

      _mostrarMensagem(
        'Não foi possível atualizar o comentário.',
      );
    }
  }

  Future<void> _eliminarComentario(
      Comentario comentario,
      ) async {
    final confirmar =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar comentário',
          ),
          content: Text(
            comentario.userId == null
                ? 'Este comentário foi publicado por um visitante. Tem a certeza de que deseja eliminá-lo?'
                : 'Tem a certeza de que deseja eliminar este comentário?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _repository.eliminarComentario(
        comentario.id,
      );

      if (!mounted) return;

      setState(() {
        _comentarios.removeWhere(
              (item) =>
          item.id == comentario.id,
        );
      });

      _mostrarMensagem(
        'Comentário eliminado.',
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'COMENTARIOS: erro ao eliminar: $e',
      );

      _mostrarMensagem(
        'Não foi possível eliminar o comentário.',
      );
    }
  }

  void _mostrarMensagem(
      String mensagem,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final local = data.toLocal();

    final dia = local.day
        .toString()
        .padLeft(2, '0');

    final mes = local.month
        .toString()
        .padLeft(2, '0');

    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 24,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
        tema.colorScheme.surface,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: tema.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_outlined,
              ),
              const SizedBox(width: 10),
              Text(
                'Comentários',
                style: tema
                    .textTheme.titleLarge
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_comentarios.length})',
                style: tema
                    .textTheme.bodyMedium
                    ?.copyWith(
                  color: tema
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller:
                  _comentarioController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction:
                  TextInputAction.newline,
                  decoration:
                  InputDecoration(
                    hintText:
                    'Escreva um comentário...',
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _enviando
                      ? null
                      : _enviarComentario,
                  child: _enviando
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Comentar',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (_carregando)
            const Center(
              child: Padding(
                padding:
                EdgeInsets.all(20),
                child:
                CircularProgressIndicator(),
              ),
            )
          else if (_comentarios.isEmpty)
            Center(
              child: Padding(
                padding:
                const EdgeInsets.all(20),
                child: Text(
                  'Ainda não existem comentários.',
                  style: tema
                      .textTheme.bodyMedium
                      ?.copyWith(
                    color: tema
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Column(
              children: _comentarios
                  .map(
                    (comentario) {
                  final meuComentario =
                      comentario.userId !=
                          null &&
                          comentario.userId ==
                              _userId;

                  final nomeUtilizador =
                  _obterNomeUtilizador(
                    comentario,
                  );

                  return Container(
                    width: double.infinity,
                    margin:
                    const EdgeInsets.only(
                      bottom: 14,
                    ),
                    padding:
                    const EdgeInsets.all(
                      16,
                    ),
                    decoration:
                    BoxDecoration(
                      color: tema
                          .colorScheme
                          .surfaceContainerLowest,
                      borderRadius:
                      BorderRadius
                          .circular(12),
                      border: Border.all(
                        color:
                        tema.dividerColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              child: Text(
                                _obterInicialNome(
                                  comentario,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                nomeUtilizador,
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _formatarData(
                                comentario
                                    .createdAt,
                              ),
                              style: tema
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          comentario
                              .comentario,
                          style: tema
                              .textTheme
                              .bodyMedium,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // Utilizador autenticado:
                        // editar e eliminar o próprio comentário.
                        //
                        // Administrador:
                        // eliminar qualquer comentário.
                        //
                        // Visitante:
                        // não pode editar nem eliminar.
                        if (meuComentario ||
                            _ehAdmin)
                          Align(
                            alignment:
                            Alignment
                                .centerRight,
                            child: Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                if (meuComentario)
                                  TextButton.icon(
                                    onPressed: () =>
                                        _editarComentario(
                                          comentario,
                                        ),
                                    icon:
                                    const Icon(
                                      Icons
                                          .edit_outlined,
                                      size: 18,
                                    ),
                                    label:
                                    const Text(
                                      'Editar',
                                    ),
                                  ),

                                if (meuComentario ||
                                    _ehAdmin)
                                  TextButton.icon(
                                    onPressed: () =>
                                        _eliminarComentario(
                                          comentario,
                                        ),
                                    icon:
                                    const Icon(
                                      Icons
                                          .delete_outline,
                                      size: 18,
                                    ),
                                    label:
                                    const Text(
                                      'Eliminar',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

