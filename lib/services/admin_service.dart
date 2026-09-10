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

  // ============================================================
  // VERIFICAR ACESSO DE ADMINISTRADOR
  // ============================================================

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

  // ============================================================
  // VERIFICAR ACESSO
  // ============================================================

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
  // CARREGAR OBRAS PENDENTES
  // ============================================================

  Future<List<ObraPendente>> carregarObrasPendentes() async {
    await _exigirAdmin();

    return await _repository.carregarTodas();
  }

  // ============================================================
  // CARREGAR UMA OBRA PENDENTE
  // ============================================================

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
  // APROVAR OBRA
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

    return await _repository.aprovar(id);
  }

  // ============================================================
  // REJEITAR OBRA
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
  // EXCLUIR OBRA PENDENTE
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
}
