
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_obra.dart';
import '../repositories/historico_obras_repository.dart';

class HistoricoObrasService {
  HistoricoObrasService._();

  static final HistoricoObrasService instancia =
  HistoricoObrasService._();

  final HistoricoObrasRepository _repository =
  HistoricoObrasRepository();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  static const int limiteHistorico = 10;

  // ============================================================
  // UTILIZADOR ATUAL
  // ============================================================

  String? get userId =>
      _supabase.auth.currentUser?.id;

  // ============================================================
  // OBTER HISTÓRICO
  // ============================================================

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

  // ============================================================
  // OBRAS RECENTES
  // ============================================================

  Future<List<HistoricoObra>> obterConsultasRecentes({
    int limite = 5,
  }) async {
    final utilizadorId = userId;

    if (utilizadorId == null) {
      return [];
    }

    final quantidade = limite > limiteHistorico
        ? limiteHistorico
        : limite;

    return await _repository.obterConsultasRecentes(
      userId: utilizadorId,
      limite: quantidade,
    );
  }

  // ============================================================
  // REGISTRAR CONSULTA
  // ============================================================

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

  // ============================================================
  // REMOVER UMA CONSULTA
  // ============================================================

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

  // ============================================================
  // LIMPAR HISTÓRICO
  // ============================================================

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

