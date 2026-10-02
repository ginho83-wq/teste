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

  Future<void> _exigirAdmin() async {
    if (!_auth.estaAutenticado) {
      throw Exception(
        'É necessário iniciar sessão para continuar.',
      );
    }

    final administrador = await _auth.ehAdmin();

    if (!administrador) {
      throw Exception(
        'Acesso reservado ao administrador.',
      );
    }
  }

  Future<bool> verificarAcesso() async {
    if (!_auth.estaAutenticado) {
      return false;
    }

    try {
      return await _auth.ehAdmin();
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // OBRAS PENDENTES
  // ============================================================

  Future<List<ObraPendente>> carregarObrasPendentes() async {
    await _exigirAdmin();

    return await _repository.carregarTodas();
  }

  Future<ObraPendente?> carregarObraPendente(
      String id,
      ) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    return await _repository.carregarPorId(id);
  }

  // ============================================================
  // OBRAS PUBLICADAS
  // ============================================================

  Future<List<Obra>> carregarObrasPublicadas() async {
    await _exigirAdmin();

    return await _obrasRepository.carregarTodas();
  }

  // ============================================================
  // APROVAR
  // ============================================================

  Future<Obra> aprovarObra(
      String id,
      ) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    final obra = await _repository.aprovar(id);

    try {
      final resposta =
      await Supabase.instance.client.functions.invoke(
        'atualizar-site',
      );

      if (resposta.status < 200 ||
          resposta.status >= 300) {
        throw Exception(
          'A Edge Function respondeu com HTTP '
              '${resposta.status}.',
        );
      }
    } catch (_) {
      throw Exception(
        'A obra foi aprovada, mas a atualização automática '
            'do site não pôde ser iniciada. Verifique a Edge '
            'Function e o GitHub Actions.',
      );
    }

    return obra;
  }

  // ============================================================
  // REJEITAR
  // ============================================================

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

  // ============================================================
  // EXCLUIR PUBLICAÇÃO PENDENTE
  // ============================================================

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

  // ============================================================
  // DELETAR OBRA PUBLICADA
  // ============================================================

  Future<void> deletarObraPublicada(
      String id,
      ) async {
    await _exigirAdmin();

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    // ----------------------------------------------------------
    // 1. ELIMINAR A OBRA
    //
    // Remove:
    // - PDF
    // - capa
    // - registo da tabela obras
    //
    // Se esta operação falhar, a eliminação é considerada
    // realmente falhada e o erro será enviado para a página.
    // ----------------------------------------------------------

    await _obrasRepository.excluirPublicada(
      idLimpo,
    );

    // ----------------------------------------------------------
    // 2. ATUALIZAR O SITE
    //
    // Esta operação acontece DEPOIS da eliminação.
    //
    // Se a Edge Function falhar, a obra já foi removida
    // do Supabase. Portanto, não devemos transformar esse
    // problema secundário em erro de eliminação.
    // ----------------------------------------------------------

    try {
      final resposta =
      await Supabase.instance.client.functions.invoke(
        'atualizar-site',
      );

      if (resposta.status < 200 ||
          resposta.status >= 300) {
        debugPrint(
          'Aviso: atualizar-site respondeu '
              'HTTP ${resposta.status}.',
        );
      }
    } catch (e) {
      debugPrint(
        'Aviso: não foi possível executar '
            'atualizar-site: $e',
      );
    }

    // ----------------------------------------------------------
    // IMPORTANTE:
    //
    // Não lançamos Exception aqui.
    //
    // A página receberá conclusão normal e apresentará:
    //
    // "Obra deletada com sucesso."
    // ----------------------------------------------------------
  }
}
