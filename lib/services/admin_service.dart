import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import 'auth_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instancia = AdminService._();

  final AuthService _auth = AuthService.instancia;

  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

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

  Future<List<ObraPendente>> carregarObrasPendentes() async {
    await _exigirAdmin();

    return await _repository.carregarTodas();
  }

  Future<ObraPendente?> carregarObraPendente(String id) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    return await _repository.carregarPorId(id);
  }

  Future<Obra> aprovarObra(String id) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    // 1. Aprova a obra no Supabase.
    final obra = await _repository.aprovar(id);

    // 2. Depois da aprovação, chama a Edge Function.
    //
    // A Edge Function verifica o administrador e
    // dispara o GitHub Actions para reconstruir o site.
    try {
      final resposta = await Supabase.instance.client.functions.invoke(
        'atualizar-site',
      );

      if (resposta.status < 200 ||
          resposta.status >= 300) {
        throw Exception(
          'A Edge Function respondeu com '
              'HTTP ${resposta.status}.',
        );
      }
    } catch (_) {
      // A obra já foi aprovada no Supabase.
      // Não tentamos desfazer a aprovação.
      throw Exception(
        'A obra foi aprovada, mas a atualização automática '
            'do site não pôde ser iniciada. '
            'Verifique a Edge Function e o GitHub Actions.',
      );
    }

    return obra;
  }

  Future<void> rejeitarObra(String id) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    await _repository.rejeitar(id);
  }

  Future<void> excluirObra(String id) async {
    await _exigirAdmin();

    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    await _repository.excluir(id);
  }
}
