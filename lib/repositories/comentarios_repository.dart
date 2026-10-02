import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comentario.dart';

class ComentariosRepository {
  ComentariosRepository._();

  static final ComentariosRepository instancia =
  ComentariosRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  /// Obtém todos os comentários de uma obra.
  Future<List<Comentario>> obterComentarios(
      String obraId,
      ) async {
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

  /// Obtém os comentários feitos nas obras
  /// de um determinado utilizador.
  Future<List<Map<String, dynamic>>>
  obterComentariosDasMinhasObras(
      String userId,
      ) async {
    final resposta = await _supabase
        .from('comentarios')
        .select('''
          id,
          obra_id,
          user_id,
          comentario,
          created_at,
          updated_at,
          obras!inner (
            id,
            titulo,
            user_id
          )
        ''')
        .eq('obras.user_id', userId)
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(
      (resposta as List).map(
            (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  /// Cria um novo comentário.
  ///
  /// Utilizador autenticado:
  /// guarda o user_id.
  ///
  /// Visitante:
  /// guarda user_id como NULL.
  Future<Comentario> criarComentario({
    required String obraId,
    required String comentario,
  }) async {
    final texto = comentario.trim();

    if (texto.isEmpty) {
      throw Exception(
        'O comentário não pode estar vazio.',
      );
    }

    final utilizador =
        _supabase.auth.currentUser;

    final dados = <String, dynamic>{
      'obra_id': obraId,
      'user_id': utilizador?.id,
      'comentario': texto,
    };

    final resposta = await _supabase
        .from('comentarios')
        .insert(dados)
        .select()
        .single();

    return Comentario.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  /// Atualiza um comentário.
  ///
  /// Apenas o utilizador autenticado
  /// que criou o comentário pode editá-lo.
  Future<Comentario> atualizarComentario({
    required String comentarioId,
    required String comentario,
  }) async {
    final utilizador =
        _supabase.auth.currentUser;

    if (utilizador == null) {
      throw Exception(
        'É necessário iniciar sessão para editar o comentário.',
      );
    }

    final texto = comentario.trim();

    if (texto.isEmpty) {
      throw Exception(
        'O comentário não pode estar vazio.',
      );
    }

    final resposta = await _supabase
        .from('comentarios')
        .update({
      'comentario': texto,
      'updated_at':
      DateTime.now().toIso8601String(),
    })
        .eq('id', comentarioId)
        .eq('user_id', utilizador.id)
        .select()
        .single();

    return Comentario.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  /// Elimina um comentário.
  ///
  /// O próprio utilizador pode eliminar
  /// o seu comentário.
  ///
  /// O administrador pode eliminar
  /// qualquer comentário, incluindo
  /// comentários de visitantes.
  Future<void> eliminarComentario(
      String comentarioId,
      ) async {
    final utilizador =
        _supabase.auth.currentUser;

    if (utilizador == null) {
      throw Exception(
        'É necessário iniciar sessão para eliminar o comentário.',
      );
    }

    await _supabase.rpc(
      'eliminar_comentario',
      params: {
        'p_comentario_id': comentarioId,
      },
    );
  }
}

