import 'package:supabase_flutter/supabase_flutter.dart';

class SolicitacoesRemocaoRepository {
  SolicitacoesRemocaoRepository._();

  static final SolicitacoesRemocaoRepository instancia =
  SolicitacoesRemocaoRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CRIAR SOLICITAÇÃO
  // ============================================================

  Future<void> criarSolicitacao({
    required String obraId,
    required String motivo,
  }) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('É necessário estar autenticado.');
    }

    final motivoLimpo = motivo.trim();

    if (motivoLimpo.isEmpty) {
      throw Exception('Informe o motivo da remoção.');
    }

    // Confirma que o utilizador possui perfil.
    final perfil = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', usuario.id)
        .maybeSingle();

    if (perfil == null) {
      throw Exception(
        'O seu perfil não foi encontrado. '
            'Entre novamente na conta ou contacte o administrador.',
      );
    }

    // Confirma que a obra existe.
    final obra = await _supabase
        .from('obras')
        .select('id')
        .eq('id', obraId)
        .maybeSingle();

    if (obra == null) {
      throw Exception('A obra não foi encontrada.');
    }

    // Só impede uma nova solicitação se houver uma
    // solicitação atualmente pendente.
    final existente = await _supabase
        .from('solicitacoes_remocao')
        .select('id')
        .eq('obra_id', obraId)
        .eq('user_id', usuario.id)
        .eq('status', 'pendente')
        .maybeSingle();

    if (existente != null) {
      throw Exception(
        'Já existe uma solicitação de remoção pendente para esta obra.',
      );
    }

    await _supabase.from('solicitacoes_remocao').insert({
      'obra_id': obraId,
      'user_id': usuario.id,
      'motivo': motivoLimpo,
      'status': 'pendente',
      'observacao_admin': null,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ============================================================
  // MINHAS SOLICITAÇÕES
  // ============================================================

  Future<List<Map<String, dynamic>>> obterMinhasSolicitacoes() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return [];
    }

    final resposta = await _supabase
        .from('solicitacoes_remocao')
        .select('''
          *,
          obras (
            id,
            titulo,
            autor,
            categoria,
            descricao
          )
        ''')
        .eq('user_id', usuario.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(resposta);
  }

  // ============================================================
  // SOLICITAÇÃO PENDENTE DE UMA OBRA
  // ============================================================

  Future<Map<String, dynamic>?> obterSolicitacaoPendente(
      String obraId,
      ) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return null;
    }

    final resposta = await _supabase
        .from('solicitacoes_remocao')
        .select()
        .eq('obra_id', obraId)
        .eq('user_id', usuario.id)
        .eq('status', 'pendente')
        .maybeSingle();

    return resposta;
  }

  // ============================================================
  // SOLICITAÇÕES PARA ADMINISTRAÇÃO
  // ============================================================

  Future<List<Map<String, dynamic>>> obterSolicitacoes({
    String? status,
  }) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('É necessário estar autenticado.');
    }

    final perfil = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', usuario.id)
        .maybeSingle();

    if (perfil == null || perfil['role'] != 'admin') {
      throw Exception(
        'Acesso permitido apenas para administradores.',
      );
    }

    var consulta = _supabase.from('solicitacoes_remocao').select('''
      *,
      obras (
        id,
        titulo,
        autor,
        categoria,
        descricao
      ),
      profiles (
        id,
        nome,
        email
      )
    ''');

    if (status != null && status.trim().isNotEmpty) {
      consulta = consulta.eq('status', status.trim());
    }

    final resposta = await consulta.order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(resposta);
  }

  // ============================================================
  // APROVAR SOLICITAÇÃO
  // ============================================================

  Future<void> aprovarSolicitacao(
      String solicitacaoId,
      ) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('É necessário estar autenticado.');
    }

    final perfil = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', usuario.id)
        .maybeSingle();

    if (perfil == null || perfil['role'] != 'admin') {
      throw Exception(
        'Apenas administradores podem aprovar solicitações.',
      );
    }

    final solicitacao = await _supabase
        .from('solicitacoes_remocao')
        .select('obra_id, status')
        .eq('id', solicitacaoId)
        .maybeSingle();

    if (solicitacao == null) {
      throw Exception('Solicitação não encontrada.');
    }

    final status = solicitacao['status']?.toString();

    if (status != 'pendente') {
      throw Exception(
        'Esta solicitação já foi processada.',
      );
    }

    final obraId = solicitacao['obra_id']?.toString();

    if (obraId == null || obraId.isEmpty) {
      throw Exception(
        'A obra associada não foi encontrada.',
      );
    }

    // Primeiro atualiza a solicitação.
    final atualizada = await _supabase
        .from('solicitacoes_remocao')
        .update({
      'status': 'aprovada',
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', solicitacaoId)
        .eq('status', 'pendente')
        .select('id');

    if (atualizada.isEmpty) {
      throw Exception(
        'A solicitação não pôde ser aprovada.',
      );
    }

    // Depois remove a obra.
    await _supabase
        .from('obras')
        .delete()
        .eq('id', obraId);
  }

  // ============================================================
  // REJEITAR SOLICITAÇÃO
  // ============================================================

  Future<void> rejeitarSolicitacao(
      String solicitacaoId, {
        String? observacao,
      }) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('É necessário estar autenticado.');
    }

    // Confirma administrador.
    final perfil = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', usuario.id)
        .maybeSingle();

    if (perfil == null || perfil['role'] != 'admin') {
      throw Exception(
        'Apenas administradores podem rejeitar solicitações.',
      );
    }

    final observacaoLimpa =
        observacao?.trim() ?? '';

    final dados = <String, dynamic>{
      'status': 'rejeitada',
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (observacaoLimpa.isNotEmpty) {
      dados['observacao_admin'] = observacaoLimpa;
    } else {
      dados['observacao_admin'] = null;
    }

    // IMPORTANTE:
    // O filtro status = pendente garante que apenas
    // uma solicitação ainda pendente possa ser rejeitada.
    final resultado = await _supabase
        .from('solicitacoes_remocao')
        .update(dados)
        .eq('id', solicitacaoId)
        .eq('status', 'pendente')
        .select('id, status, observacao_admin');

    if (resultado.isEmpty) {
      throw Exception(
        'A solicitação não foi encontrada, '
            'já foi processada ou não está mais pendente.',
      );
    }

    // Confirma que o Supabase realmente gravou
    // o novo estado.
    final confirmacao = await _supabase
        .from('solicitacoes_remocao')
        .select('status')
        .eq('id', solicitacaoId)
        .maybeSingle();

    if (confirmacao == null ||
        confirmacao['status']?.toString() != 'rejeitada') {
      throw Exception(
        'A rejeição não foi gravada corretamente.',
      );
    }
  }

  // ============================================================
  // OBTER SOLICITAÇÃO POR ID
  // ============================================================

  Future<Map<String, dynamic>?> obterPorId(
      String solicitacaoId,
      ) async {
    final resposta = await _supabase
        .from('solicitacoes_remocao')
        .select('''
          *,
          obras (
            id,
            titulo,
            autor,
            categoria,
            descricao
          ),
          profiles (
            id,
            nome,
            email
          )
        ''')
        .eq('id', solicitacaoId)
        .maybeSingle();

    return resposta;
  }
}

