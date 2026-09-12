import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_obra.dart';

class HistoricoObrasRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Regista uma obra como consultada.
  ///
  /// Se a obra já estiver no histórico do utilizador,
  /// apenas atualiza a data da última consulta.
  Future<void> registrarConsulta({
    required String obraId,
    required String userId,
  }) async {
    try {
      final existente = await _supabase
          .from('historico_obras_consultadas')
          .select('id')
          .eq('obra_id', obraId)
          .eq('user_id', userId)
          .maybeSingle();

      final agora = DateTime.now().toUtc().toIso8601String();

      if (existente != null) {
        await _supabase
            .from('historico_obras_consultadas')
            .update({
          'data_consulta': agora,
        })
            .eq('id', existente['id'])
            .eq('user_id', userId);
      } else {
        await _supabase
            .from('historico_obras_consultadas')
            .insert({
          'obra_id': obraId,
          'user_id': userId,
          'data_consulta': agora,
        });
      }
    } catch (e) {
      debugPrint('Erro ao registrar consulta: $e');
      rethrow;
    }
  }

  /// Obtém todo o histórico do utilizador.
  Future<List<HistoricoObra>> obterHistorico({
    required String userId,
  }) async {
    try {
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
    } catch (e) {
      debugPrint('Erro ao obter histórico: $e');
      rethrow;
    }
  }

  /// Obtém somente as últimas consultas.
  ///
  /// É utilizado pela Home.
  Future<List<HistoricoObra>> obterConsultasRecentes({
    required String userId,
    int limite = 5,
  }) async {
    try {
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
          .order('data_consulta', ascending: false)
          .limit(limite);

      final lista = (response as List)
          .map(
            (item) => HistoricoObra.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      debugPrint(
        'Histórico: ${lista.length} consultas encontradas para $userId',
      );

      return lista;
    } catch (e) {
      debugPrint('Erro ao obter consultas recentes: $e');
      rethrow;
    }
  }

  /// Remove uma consulta específica.
  Future<void> removerConsulta({
    required String id,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Utilizador não autenticado.');
      }

      await _supabase
          .from('historico_obras_consultadas')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Erro ao remover consulta: $e');
      rethrow;
    }
  }

  /// Remove todo o histórico do utilizador.
  Future<void> limparHistorico({
    required String userId,
  }) async {
    try {
      await _supabase
          .from('historico_obras_consultadas')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Erro ao limpar histórico: $e');
      rethrow;
    }
  }
}

