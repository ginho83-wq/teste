import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_obra.dart';
import '../repositories/historico_obras_repository.dart';

class HistoricoObrasService {
  final HistoricoObrasRepository _repository =
  HistoricoObrasRepository();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtém o utilizador atualmente autenticado.
  String? get userId => _supabase.auth.currentUser?.id;

  /// Obtém o histórico do utilizador autenticado.
  Future<List<HistoricoObra>> obterHistorico() async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      throw Exception('Utilizador não autenticado.');
    }

    return await _repository.obterHistorico(
      userId: utilizadorId,
    );
  }

  /// Regista uma obra como consultada.
  Future<void> registrarConsulta({
    required String obraId,
  }) async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      throw Exception('Utilizador não autenticado.');
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
      throw Exception('Utilizador não autenticado.');
    }

    await _repository.removerConsulta(
      id: id,
    );
  }

  /// Limpa todo o histórico do utilizador.
  Future<void> limparHistorico() async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      throw Exception('Utilizador não autenticado.');
    }

    await _repository.limparHistorico(
      userId: utilizadorId,
    );
  }
}

