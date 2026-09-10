import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/perfil.dart';
import '../services/supabase_service.dart';

class ProfilesRepository {
  ProfilesRepository._();

  static final ProfilesRepository instancia = ProfilesRepository._();

  final SupabaseClient _supabase = SupabaseService.instancia.client;

  static const String _tabela = 'profiles';

  // ============================================================
  // CARREGAR PERFIL POR ID
  // ============================================================

  Future<Perfil?> carregarPorId(String id) async {
    final resposta = await _supabase
        .from(_tabela)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return Perfil.fromMap(resposta);
  }

  // ============================================================
  // CARREGAR MEU PERFIL
  // ============================================================

  Future<Perfil?> carregarMeuPerfil() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return null;
    }

    return carregarPorId(usuario.id);
  }

  // ============================================================
  // VERIFICAR SE O UTILIZADOR É ADMIN
  // ============================================================

  Future<bool> ehAdmin() async {
    final perfil = await carregarMeuPerfil();

    return perfil?.role == 'admin';
  }

  // ============================================================
  // CARREGAR PERFIS
  // ============================================================

  Future<List<Perfil>> carregarPerfis({
    int pagina = 1,
    int porPagina = 10,
  }) async {
    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select()
        .order('created_at', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Perfil.fromMap(item))
        .toList();
  }

  // ============================================================
  // PESQUISAR PERFIS
  // ============================================================

  Future<List<Perfil>> pesquisar(
      String termo, {
        int pagina = 1,
        int porPagina = 10,
      }) async {
    final texto = termo.trim();

    if (texto.isEmpty) {
      return carregarPerfis(
        pagina: pagina,
        porPagina: porPagina,
      );
    }

    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select()
        .or(
      'nome.ilike.%$texto%,email.ilike.%$texto%',
    )
        .order('created_at', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Perfil.fromMap(item))
        .toList();
  }

  // ============================================================
  // CARREGAR POR ROLE
  // ============================================================

  Future<List<Perfil>> carregarPorRole(
      String role, {
        int pagina = 1,
        int porPagina = 10,
      }) async {
    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select()
        .eq('role', role)
        .order('created_at', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Perfil.fromMap(item))
        .toList();
  }

  // ============================================================
  // INSERIR PERFIL
  // ============================================================

  Future<Perfil> inserir(Perfil perfil) async {
    final dados = {
      'id': perfil.id,
      'nome': perfil.nome,
      'email': perfil.email,
      'role': perfil.role,
    };

    final resposta = await _supabase
        .from(_tabela)
        .insert(dados)
        .select()
        .single();

    return Perfil.fromMap(resposta);
  }

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  Future<Perfil> atualizar(Perfil perfil) async {
    final dados = {
      'nome': perfil.nome,
      'email': perfil.email,
      'role': perfil.role,
    };

    final resposta = await _supabase
        .from(_tabela)
        .update(dados)
        .eq('id', perfil.id)
        .select()
        .single();

    return Perfil.fromMap(resposta);
  }

  // ============================================================
  // EXCLUIR PERFIL
  // ============================================================

  Future<void> excluir(String id) async {
    await _supabase
        .from(_tabela)
        .delete()
        .eq('id', id);
  }

  // ============================================================
  // CONTAR PERFIS
  // ============================================================

  Future<int> contarPerfis() async {
    final resposta = await _supabase
        .from(_tabela)
        .select('id');

    return (resposta as List).length;
  }

  // ============================================================
  // CONTAR POR ROLE
  // ============================================================

  Future<int> contarPorRole(String role) async {
    final resposta = await _supabase
        .from(_tabela)
        .select('id')
        .eq('role', role);

    return (resposta as List).length;
  }
}

