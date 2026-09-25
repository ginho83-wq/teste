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
  State<ComentariosSection> createState() => _ComentariosSectionState();
}

class _ComentariosSectionState extends State<ComentariosSection> {
  final ComentariosRepository _repository =
      ComentariosRepository.instancia;

  final TextEditingController _comentarioController =
  TextEditingController();

  List<Comentario> _comentarios = [];

  bool _carregando = true;
  bool _enviando = false;

  String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  bool get _utilizadorAutenticado => _userId != null;

  @override
  void initState() {
    super.initState();
    _carregarComentarios();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _carregarComentarios() async {
    setState(() {
      _carregando = true;
    });

    try {
      final comentarios =
      await _repository.obterComentarios(widget.obraId);

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

      _mostrarMensagem(
        'Não foi possível carregar os comentários.',
      );
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();

    if (texto.isEmpty) {
      _mostrarMensagem('Escreva um comentário.');
      return;
    }

    if (!_utilizadorAutenticado) {
      _mostrarMensagem(
        'Inicie sessão para poder comentar.',
      );
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final novoComentario =
      await _repository.criarComentario(
        obraId: widget.obraId,
        comentario: texto,
      );

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

      _mostrarMensagem(
        'Não foi possível publicar o comentário.',
      );
    }
  }

  Future<void> _editarComentario(Comentario comentario) async {
    final controller = TextEditingController(
      text: comentario.comentario,
    );

    final novoTexto = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar comentário'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Escreva o seu comentário...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final texto = controller.text.trim();

                if (texto.isNotEmpty) {
                  Navigator.pop(context, texto);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (novoTexto == null ||
        novoTexto.trim().isEmpty ||
        novoTexto.trim() == comentario.comentario) {
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
        final indice = _comentarios.indexWhere(
              (item) => item.id == comentario.id,
        );

        if (indice != -1) {
          _comentarios[indice] = atualizado;
        }
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível atualizar o comentário.',
      );
    }
  }

  Future<void> _eliminarComentario(Comentario comentario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar comentário'),
          content: const Text(
            'Tem a certeza de que deseja eliminar este comentário?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _repository.eliminarComentario(comentario.id);

      if (!mounted) return;

      setState(() {
        _comentarios.removeWhere(
              (item) => item.id == comentario.id,
        );
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível eliminar o comentário.',
      );
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final local = data.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tema.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined),
              const SizedBox(width: 10),
              Text(
                'Comentários',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_comentarios.length})',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_utilizadorAutenticado)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentarioController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Escreva um comentário...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
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
                    onPressed:
                    _enviando ? null : _enviarComentario,
                    child: _enviando
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Comentar'),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Inicie sessão para deixar um comentário.',
              ),
            ),

          const SizedBox(height: 24),

          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_comentarios.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Ainda não existem comentários.',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Column(
              children: _comentarios.map(
                    (comentario) {
                  final meuComentario =
                      comentario.userId == _userId;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tema
                          .colorScheme
                          .surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
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
                            CircleAvatar(
                              radius: 18,
                              child: Text(
                                comentario.userId
                                    .substring(0, 1)
                                    .toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                meuComentario
                                    ? 'Você'
                                    : 'Utilizador',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _formatarData(
                                comentario.createdAt,
                              ),
                              style:
                              tema.textTheme.bodySmall,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          comentario.comentario,
                          style: tema.textTheme.bodyMedium,
                        ),

                        if (meuComentario)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _editarComentario(
                                        comentario,
                                      ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _eliminarComentario(
                                        comentario,
                                      ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
        ],
      ),
    );
  }
}

