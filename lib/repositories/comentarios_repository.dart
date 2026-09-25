import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comentario.dart';

class ComentariosRepository {
  ComentariosRepository._();

  static final ComentariosRepository instancia =
  ComentariosRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtém todos os comentários de uma obra.
  Future<List<Comentario>> obterComentarios(String obraId) async {
    final resposta = await _supabase
        .from('comentarios')
        .select()
        .eq('obra_id', obraId)
        .order('created_at', ascending: true);

    return (resposta as List)
        .map(
          (item) => Comentario.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  /// Cria um novo comentário.
  Future<Comentario> criarComentario({
    required String obraId,
    required String comentario,
  }) async {
    final utilizador = _supabase.auth.currentUser;

    if (utilizador == null) {
      throw Exception('É necessário iniciar sessão para comentar.');
    }

    final texto = comentario.trim();

    if (texto.isEmpty) {
      throw Exception('O comentário não pode estar vazio.');
    }

    final resposta = await _supabase
        .from('comentarios')
        .insert({
      'obra_id': obraId,
      'user_id': utilizador.id,
      'comentario': texto,
    })
        .select()
        .single();

    return Comentario.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  /// Atualiza um comentário existente.
  Future<Comentario> atualizarComentario({
    required String comentarioId,
    required String comentario,
  }) async {
    final texto = comentario.trim();

    if (texto.isEmpty) {
      throw Exception('O comentário não pode estar vazio.');
    }

    final resposta = await _supabase
        .from('comentarios')
        .update({
      'comentario': texto,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', comentarioId)
        .select()
        .single();

    return Comentario.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  /// Elimina um comentário.
  Future<void> eliminarComentario(String comentarioId) async {
    await _supabase
        .from('comentarios')
        .delete()
        .eq('id', comentarioId);
  }
}

