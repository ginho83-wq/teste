import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_obra.dart';

class HistoricoObrasRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Regista uma obra como consultada pelo utilizador.
  Future<void> registrarConsulta({
    required String obraId,
    required String userId,
  }) async {
    await _supabase
        .from('historico_obras_consultadas')
        .insert({
      'obra_id': obraId,
      'user_id': userId,
    });
  }

  /// Obtém o histórico do utilizador autenticado.
  Future<List<HistoricoObra>> obterHistorico({
    required String userId,
  }) async {
    final response = await _supabase
        .from('historico_obras_consultadas')
        .select('''
          id,
          obra_id,
          user_id,
          data_consulta,
          created_at,
          obras (
            titulo,
            autor,
            categoria,
            descricao,
            url_documento
          )
        ''')
        .eq('user_id', userId)
        .order('data_consulta', ascending: false);

    return (response as List)
        .map(
          (item) => HistoricoObra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  /// Remove um item específico do histórico.
  Future<void> removerConsulta({
    required String id,
  }) async {
    await _supabase
        .from('historico_obras_consultadas')
        .delete()
        .eq('id', id);
  }

  /// Remove todo o histórico do utilizador.
  Future<void> limparHistorico({
    required String userId,
  }) async {
    await _supabase
        .from('historico_obras_consultadas')
        .delete()
        .eq('user_id', userId);
  }
}
