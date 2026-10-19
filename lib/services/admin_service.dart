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

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================================
  // VERIFICAR ADMINISTRADOR
  // ==========================================================

  Future<void> _exigirAdmin() async {
    final utilizador = _supabase.auth.currentUser;

    if (utilizador == null) {
      throw Exception('É necessário iniciar sessão.');
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

  Future<ObraPendente> carregarObraPendente(String id) async {
    await _exigirAdmin();

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception('ID da obra inválido.');
    }

    final obra = await _repository.carregarPorId(idLimpo);

    if (obra == null) {
      throw Exception('Obra pendente não encontrada.');
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

  Future<Obra> aprovarObra(String id) async {
    await _exigirAdmin();

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception('ID da obra inválido.');
    }

    // O repositório aprova a obra e o trigger SQL existente
    // trata da criação da divulgação na fila.
    final obra = await _repository.aprovar(idLimpo);

    // Actualizar o site sem invalidar a aprovação se a função
    // de actualização falhar.
    try {
      final resposta = await _supabase.functions.invoke(
        'atualizar-site',
      );

      if (resposta.status < 200 || resposta.status >= 300) {
        debugPrint(
          'Aviso: atualizar-site respondeu HTTP '
              '${resposta.status}.',
        );
      } else {
        debugPrint('atualizar-site iniciado com sucesso.');
      }
    } catch (e) {
      debugPrint('Aviso: não foi possível actualizar o site: $e');
    }

    // Enviar o email de aprovação.
    try {
      final resposta = await _supabase.functions.invoke(
        'enviar-email-aprovacao',
        body: {'obra_id': obra.id},
      );

      if (resposta.status < 200 || resposta.status >= 300) {
        debugPrint(
          'Aviso: email de aprovação não enviado. '
              'HTTP ${resposta.status}. Resposta: ${resposta.data}',
        );
      } else {
        debugPrint('Email de aprovação enviado com sucesso.');
      }
    } catch (e) {
      debugPrint('Aviso: erro ao enviar email de aprovação: $e');
    }

    // Não chamar a função Facebook aqui automaticamente.
    // A fila é criada pelo trigger; a divulgação é processada
    // pelo botão do painel ou por um agendamento seguro.
    return obra;
  }

  // ==========================================================
  // DIVULGAR OBRAS PENDENTES NO FACEBOOK
  // ==========================================================

  Future<Map<String, dynamic>> divulgarObrasFacebook() async {
    await _exigirAdmin();

    try {
      final resposta = await _supabase.functions.invoke(
        'divulgar-obras-facebook',
        method: HttpMethod.post,
      );

      final dados = resposta.data;

      if (resposta.status < 200 || resposta.status >= 300) {
        throw Exception(
          'A função Facebook respondeu HTTP ${resposta.status}. '
              '${dados ?? ''}',
        );
      }

      if (dados is Map) {
        final resultado = Map<String, dynamic>.from(dados);

        if (resultado['sucesso'] == false) {
          throw Exception(
            resultado['erro']?.toString() ??
                'Não foi possível divulgar as obras no Facebook.',
          );
        }

        return resultado;
      }

      throw Exception(
        'A função Facebook devolveu uma resposta inesperada.',
      );
    } on FunctionException catch (e) {
      debugPrint(
        'Erro na função divulgar-obras-facebook: '
            '${e.status}, ${e.details}',
      );

      throw Exception(
        'Não foi possível executar a divulgação no Facebook. '
            'Verifique a autorização da função e os segredos configurados '
            'no Supabase.',
      );
    } catch (e) {
      debugPrint('Erro na divulgação Facebook: $e');
      rethrow;
    }
  }

  // ==========================================================
  // REJEITAR OBRA
  // ==========================================================

  Future<void> rejeitarObra(String id) async {
    await _exigirAdmin();

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception('ID da obra inválido.');
    }

    await _repository.rejeitar(idLimpo);
  }

  // ==========================================================
  // EXCLUIR OBRA PENDENTE
  // ==========================================================

  Future<void> excluirObra(String id) async {
    await _exigirAdmin();

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception('ID da obra inválido.');
    }

    await _repository.excluir(idLimpo);
  }

  // ==========================================================
  // ELIMINAR OBRA PUBLICADA
  // ==========================================================

  Future<void> deletarObraPublicada(String id) async {
    await _exigirAdmin();

    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception('ID da obra inválido.');
    }

    // 1. Apagar as secções.
    try {
      await _supabase
          .from('teste_secoes')
          .delete()
          .eq('obra_id', idLimpo);

      debugPrint('Secções da obra eliminadas.');
    } catch (e) {
      debugPrint(
        'Aviso: não foi possível eliminar as secções: $e',
      );
    }

    // 2. Apagar a obra publicada.
    await _obrasRepository.excluirPublicada(idLimpo);

    // 3. Actualizar o site.
    try {
      final resposta = await _supabase.functions.invoke(
        'atualizar-site',
      );

      if (resposta.status < 200 || resposta.status >= 300) {
        debugPrint(
          'Aviso: atualizar-site respondeu HTTP '
              '${resposta.status}.',
        );
      }
    } catch (e) {
      debugPrint(
        'Aviso: não foi possível actualizar o site: $e',
      );
    }
  }
}

