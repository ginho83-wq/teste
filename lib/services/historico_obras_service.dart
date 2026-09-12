import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_obra.dart';
import '../repositories/historico_obras_repository.dart';

class HistoricoObrasService {
  final HistoricoObrasRepository _repository =
  HistoricoObrasRepository();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  /// ID do utilizador atualmente autenticado.
  String? get userId =>
      _supabase.auth.currentUser?.id;

  /// Obtém o histórico completo.
  Future<List<HistoricoObra>> obterHistorico() async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      throw Exception(
        'Utilizador não autenticado.',
      );
    }

    return await _repository.obterHistorico(
      userId: utilizadorId,
    );
  }

  /// Obtém apenas as últimas consultas.
  ///
  /// Por padrão, devolve as 5 últimas.
  Future<List<HistoricoObra>> obterConsultasRecentes({
    int limite = 5,
  }) async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      return [];
    }

    return await _repository.obterConsultasRecentes(
      userId: utilizadorId,
      limite: limite,
    );
  }

  /// Regista uma obra como consultada.
  Future<void> registrarConsulta({
    required String obraId,
  }) async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      throw Exception(
        'Utilizador não autenticado.',
      );
    }

    await _repository.registrarConsulta(
      obraId: obraId,
      userId: utilizadorId,
    );
  }

  /// Remove uma consulta específica.
  Future<void> removerConsulta({
    required String id,
  }) async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      throw Exception(
        'Utilizador não autenticado.',
      );
    }

    await _repository.removerConsulta(
      id: id,
    );
  }

  /// Limpa todo o histórico.
  Future<void> limparHistorico() async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      throw Exception(
        'Utilizador não autenticado.',
      );
    }

    await _repository.limparHistorico(
      userId: utilizadorId,
    );
  }
}
