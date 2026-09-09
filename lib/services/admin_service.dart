import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import 'auth_service.dart';

class AdminService {
  AdminService._();

  static final AdminService instancia =
  AdminService._();

  final AuthService _auth =
      AuthService.instancia;

  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

  // ============================================================
  // VERIFICAR ACESSO ADMINISTRATIVO
  // ============================================================

  Future<void> _exigirAdmin() async {
    final autenticado = _auth.estaAutenticado;

    if (!autenticado) {
      throw Exception(
        'É necessário iniciar sessão.',
      );
    }

    final ehAdmin = await _auth.ehAdmin();

    if (!ehAdmin) {
      throw Exception(
        'Acesso negado. Apenas administradores podem executar esta operação.',
      );
    }
  }

  // ============================================================
  // LISTAR OBRAS PENDENTES
  // ============================================================

  Future<List<ObraPendente>> carregarObrasPendentes() async {
    await _exigirAdmin();

    return await _repository.carregarTodas();
  }

  // ============================================================
  // BUSCAR OBRA PENDENTE
  // ============================================================

  Future<ObraPendente?> carregarObraPendente(
      String id,
      ) async {
    await _exigirAdmin();

    return await _repository.carregarPorId(id);
  }

  // ============================================================
  // APROVAR OBRA
  // ============================================================

  Future<Obra> aprovarObra(
      String id,
      ) async {
    await _exigirAdmin();

    return await _repository.aprovar(id);
  }

  // ============================================================
  // REJEITAR OBRA
  // ============================================================

  Future<void> rejeitarObra(
      String id,
      ) async {
    await _exigirAdmin();

    await _repository.rejeitar(id);
  }

  // ============================================================
  // EXCLUIR OBRA PENDENTE
  // ============================================================

  Future<void> excluirObra(
      String id,
      ) async {
    await _exigirAdmin();

    await _repository.excluir(id);
  }

  // ============================================================
  // VERIFICAR SE O UTILIZADOR ATUAL É ADMIN
  // ============================================================

  Future<bool> verificarAcesso() async {
    if (!_auth.estaAutenticado) {
      return false;
    }

    return await _auth.ehAdmin();
  }
}

