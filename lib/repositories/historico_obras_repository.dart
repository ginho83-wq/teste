import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_obra.dart';

class HistoricoObrasRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int limiteHistorico = 10;

  // ============================================================
  // REGISTRAR CONSULTA
  // ============================================================

  Future<void> registrarConsulta({
    required String obraId,
    required String userId,
  }) async {
    try {
      final agora = DateTime.now().toUtc().toIso8601String();

      // --------------------------------------------------------
      // Verificar se a obra já existe no histórico
      // --------------------------------------------------------

      final existentes = await _supabase
          .from('historico_obras_consultadas')
          .select('id, data_consulta')
          .eq('obra_id', obraId)
          .eq('user_id', userId)
          .order('data_consulta', ascending: false);

      if (existentes is List && existentes.isNotEmpty) {
        // Mantém o registo mais recente e atualiza a data.
        final id = existentes.first['id'];

        await _supabase
            .from('historico_obras_consultadas')
            .update({
          'data_consulta': agora,
        })
            .eq('id', id)
            .eq('user_id', userId);

        // Se existirem duplicados antigos da mesma obra,
        // removemos os restantes.
        if (existentes.length > 1) {
          for (var i = 1; i < existentes.length; i++) {
            final idDuplicado = existentes[i]['id'];

            await _supabase
                .from('historico_obras_consultadas')
                .delete()
                .eq('id', idDuplicado)
                .eq('user_id', userId);
          }
        }

        debugPrint(
          'HISTÓRICO: obra $obraId voltou para o topo.',
        );
      } else {
        // ------------------------------------------------------
        // Obra nova
        // ------------------------------------------------------

        await _supabase
            .from('historico_obras_consultadas')
            .insert({
          'obra_id': obraId,
          'user_id': userId,
          'data_consulta': agora,
        });

        debugPrint(
          'HISTÓRICO: nova obra $obraId registrada.',
        );
      }

      // --------------------------------------------------------
      // Manter somente as 10 consultas mais recentes
      // --------------------------------------------------------

      await _limitarHistorico(userId);
    } catch (e) {
      debugPrint(
        'HISTÓRICO: erro ao registrar consulta: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // LIMITAR HISTÓRICO A 10 REGISTOS
  // ============================================================

  Future<void> _limitarHistorico(String userId) async {
    final response = await _supabase
        .from('historico_obras_consultadas')
        .select('id')
        .eq('user_id', userId)
        .order(
      'data_consulta',
      ascending: false,
    );

    final lista = response as List;

    if (lista.length <= limiteHistorico) {
      return;
    }

    // Tudo depois do décimo item é considerado antigo.
    final antigos = lista.skip(limiteHistorico);

    for (final item in antigos) {
      final id = item['id'];

      await _supabase
          .from('historico_obras_consultadas')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    }

    debugPrint(
      'HISTÓRICO: histórico limitado a '
          '$limiteHistorico obras.',
    );
  }

  // ============================================================
  // HISTÓRICO COMPLETO
  // ============================================================

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
          .order(
        'data_consulta',
        ascending: false,
      )
          .limit(limiteHistorico);

      return (response as List)
          .map(
            (item) => HistoricoObra.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    } catch (e) {
      debugPrint(
        'HISTÓRICO: erro ao obter histórico: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // CONSULTAS RECENTES
  // ============================================================

  Future<List<HistoricoObra>> obterConsultasRecentes({
    required String userId,
    int limite = 5,
  }) async {
    try {
      final quantidade = limite > limiteHistorico
          ? limiteHistorico
          : limite;

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
          .order(
        'data_consulta',
        ascending: false,
      )
          .limit(quantidade);

      final lista = (response as List)
          .map(
            (item) => HistoricoObra.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      debugPrint(
        'HISTÓRICO: ${lista.length} consultas encontradas.',
      );

      return lista;
    } catch (e) {
      debugPrint(
        'HISTÓRICO: erro ao obter consultas recentes: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // REMOVER UMA CONSULTA
  // ============================================================

  Future<void> removerConsulta({
    required String id,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(
          'Utilizador não autenticado.',
        );
      }

      await _supabase
          .from('historico_obras_consultadas')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint(
        'HISTÓRICO: erro ao remover consulta: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // LIMPAR TODO O HISTÓRICO
  // ============================================================

  Future<void> limparHistorico({
    required String userId,
  }) async {
    try {
      await _supabase
          .from('historico_obras_consultadas')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint(
        'HISTÓRICO: erro ao limpar histórico: $e',
      );

      rethrow;
    }
  }
}
