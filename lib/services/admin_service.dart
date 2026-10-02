import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import '../repositories/obras_repository.dart';
import 'auth_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instancia = AdminService._();

  final AuthService _auth = AuthService.instancia;

  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  // ==========================================================
  // VERIFICAR ADMINISTRADOR
  // ==========================================================

  Future<void> _exigirAdmin() async {
    final utilizador =
        Supabase.instance.client.auth.currentUser;

    if (utilizador == null) {
      throw Exception(
        'É necessário iniciar sessão.',
      );
    }

    final ehAdmin = await _auth.ehAdmin();

    if (!ehAdmin) {
      throw Exception(
        'Acesso permitido apenas a administradores.',
      );
    }
  }

  // ==========================================================
  // CARREGAR OBRAS PENDENTES
  // ==========================================================

  Future<List<ObraPendente>> carregarObrasPendentes() async {
    await _exigirAdmin();

    return _repository.carregarTodas();
  }

  // ==========================================================
  // CARREGAR UMA OBRA PENDENTE
  // ==========================================================

  Future<ObraPendente> carregarObraPendente(
      String id,
      ) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    final obra =
    await _repository.carregarPorId(id);

    if (obra == null) {
      throw Exception(
        'Obra pendente não encontrada.',
      );
    }

    return obra;
  }

  // ==========================================================
  // CARREGAR OBRAS PUBLICADAS
  // ==========================================================

  Future<List<Obra>> carregarObrasPublicadas() async {
    await _exigirAdmin();

    return _obrasRepository.carregarTodas();
  }

  // ==========================================================
  // APROVAR OBRA
  // ==========================================================

  Future<Obra> aprovarObra(
      String id,
      ) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    // --------------------------------------------------------
    // 1. Aprovar e publicar a obra
    // --------------------------------------------------------

    final obra =
    await _repository.aprovar(id);

    // --------------------------------------------------------
    // 2. Atualizar o site
    // --------------------------------------------------------

    try {
      final resposta =
      await Supabase.instance.client.functions.invoke(
        'atualizar-site',
      );

      if (resposta.status < 200 ||
          resposta.status >= 300) {
        debugPrint(
          'Aviso: atualizar-site respondeu HTTP '
              '${resposta.status}.',
        );
      } else {
        debugPrint(
          'atualizar-site iniciado com sucesso.',
        );
      }
    } catch (e) {
      // A obra já foi publicada.
      // Um erro no GitHub/site não deve desfazer a aprovação.
      debugPrint(
        'Aviso: não foi possível iniciar atualizar-site: $e',
      );
    }

    // --------------------------------------------------------
    // 3. Enviar e-mail ao proprietário da obra
    // --------------------------------------------------------

    try {
      final resposta =
      await Supabase.instance.client.functions.invoke(
        'enviar-email-aprovacao',
        body: {
          'obra_id': obra.id,
        },
      );

      if (resposta.status < 200 ||
          resposta.status >= 300) {
        debugPrint(
          'Aviso: e-mail de aprovação não enviado. '
              'HTTP ${resposta.status}.',
        );

        debugPrint(
          'Resposta da Edge Function: '
              '${resposta.data}',
        );
      } else {
        debugPrint(
          'E-mail de aprovação enviado com sucesso.',
        );
      }
    } catch (e) {
      // O e-mail é uma operação secundária.
      // A obra continua aprovada/publicada.
      debugPrint(
        'Aviso: erro ao enviar e-mail de aprovação: $e',
      );
    }

    // --------------------------------------------------------
    // 4. Devolver a obra publicada
    // --------------------------------------------------------

    return obra;
  }

  // ==========================================================
  // REJEITAR OBRA
  // ==========================================================

  Future<void> rejeitarObra(
      String id,
      ) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    await _repository.rejeitar(id);
  }

  // ==========================================================
  // EXCLUIR OBRA PENDENTE
  // ==========================================================

  Future<void> excluirObra(
      String id,
      ) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    await _repository.excluir(id);
  }

  // ==========================================================
  // ELIMINAR OBRA PUBLICADA
  // ==========================================================

  Future<void> deletarObraPublicada(
      String id,
      ) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    // --------------------------------------------------------
    // 1. Apagar a obra
    // --------------------------------------------------------

    await _obrasRepository.excluirPublicada(id);

    // --------------------------------------------------------
    // 2. Atualizar o site
    // --------------------------------------------------------

    try {
      final resposta =
      await Supabase.instance.client.functions.invoke(
        'atualizar-site',
      );

      if (resposta.status < 200 ||
          resposta.status >= 300) {
        debugPrint(
          'Aviso: atualizar-site respondeu HTTP '
              '${resposta.status}.',
        );
      }
    } catch (e) {
      // A obra já foi eliminada.
      // O erro de atualização do site não desfaz a eliminação.
      debugPrint(
        'Aviso: não foi possível iniciar atualizar-site: $e',
      );
    }
  }
}

