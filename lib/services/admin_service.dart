import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import '../repositories/obras_repository.dart';
import 'auth_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instancia =
  AdminService._();

  final AuthService _auth =
      AuthService.instancia;

  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================================
  // VERIFICAR ADMINISTRADOR
  // ==========================================================

  Future<void> _exigirAdmin() async {
    final utilizador =
        _supabase.auth.currentUser;

    if (utilizador == null) {
      throw Exception(
        'É necessário iniciar sessão.',
      );
    }

    final ehAdmin =
    await _auth.ehAdmin();

    if (!ehAdmin) {
      throw Exception(
        'Acesso permitido apenas a administradores.',
      );
    }
  }

  // ==========================================================
  // CARREGAR OBRAS PENDENTES
  // ==========================================================

  Future<List<ObraPendente>>
  carregarObrasPendentes() async {
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

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    final obra =
    await _repository.carregarPorId(
      idLimpo,
    );

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

  Future<List<Obra>>
  carregarObrasPublicadas() async {
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

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    // --------------------------------------------------------
    // APROVAR A OBRA
    //
    // O ObrasPendentesRepository é responsável por:
    //
    // 1. Carregar a obra pendente
    // 2. Transferir o PDF
    // 3. Criar a obra em public.obras
    // 4. Criar as secções em public.teste_secoes
    // 5. Remover a obra pendente
    // --------------------------------------------------------

    final obra =
    await _repository.aprovar(
      idLimpo,
    );

    // --------------------------------------------------------
    // ATUALIZAR O SITE
    // --------------------------------------------------------

    try {
      final resposta =
      await _supabase.functions.invoke(
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
      debugPrint(
        'Aviso: não foi possível iniciar '
            'atualizar-site: $e',
      );
    }

    // --------------------------------------------------------
    // ENVIAR E-MAIL AO PROPRIETÁRIO
    // --------------------------------------------------------

    try {
      final resposta =
      await _supabase.functions.invoke(
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
      debugPrint(
        'Aviso: erro ao enviar e-mail de aprovação: $e',
      );
    }

    // --------------------------------------------------------
    // DEVOLVER OBRA PUBLICADA
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

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    await _repository.rejeitar(
      idLimpo,
    );
  }

  // ==========================================================
  // EXCLUIR OBRA PENDENTE
  // ==========================================================

  Future<void> excluirObra(
      String id,
      ) async {
    await _exigirAdmin();

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    await _repository.excluir(
      idLimpo,
    );
  }

  // ==========================================================
  // ELIMINAR OBRA PUBLICADA
  // ==========================================================

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

    // --------------------------------------------------------
    // 1. APAGAR AS SECÇÕES DA OBRA
    // --------------------------------------------------------

    try {
      await _supabase
          .from('teste_secoes')
          .delete()
          .eq(
        'obra_id',
        idLimpo,
      );

      debugPrint(
        'Secções da obra eliminadas.',
      );
    } catch (e) {
      debugPrint(
        'Aviso: não foi possível eliminar '
            'as secções da obra: $e',
      );
    }

    // --------------------------------------------------------
    // 2. APAGAR A OBRA
    // --------------------------------------------------------

    await _obrasRepository.excluirPublicada(
      idLimpo,
    );

    // --------------------------------------------------------
    // 3. ATUALIZAR O SITE
    // --------------------------------------------------------

    try {
      final resposta =
      await _supabase.functions.invoke(
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
      debugPrint(
        'Aviso: não foi possível iniciar '
            'atualizar-site: $e',
      );
    }
  }
}

