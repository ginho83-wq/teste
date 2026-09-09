import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../services/supabase_service.dart';

class ObrasRepository {
  ObrasRepository._();

  static final ObrasRepository instancia = ObrasRepository._();

  final SupabaseClient _supabase = SupabaseService.instancia.client;

  static const String _tabela = 'obras';

  static const String _campos = '''
    id,
    titulo,
    descricao,
    autor,
    categoria,
    url_documento,
    ano_obra,
    data_publicacao,
    user_id,
    created_at,
    updated_at
  ''';

  // ============================================================
  // CARREGAR OBRA POR ID
  // ============================================================

  Future<Obra?> carregarPorId(String id) async {
    final resposta = await _supabase
        .from(_tabela)
        .select(_campos)
        .eq('id', id)
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return Obra.fromMap(resposta);
  }

  // ============================================================
  // CARREGAR OBRAS
  // ============================================================

  Future<List<Obra>> carregarObras({
    int pagina = 1,
    int porPagina = 10,
  }) async {
    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select(_campos)
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(item))
        .toList();
  }

  // ============================================================
  // PESQUISAR
  // ============================================================

  Future<List<Obra>> pesquisar(
      String termo, {
        int pagina = 1,
        int porPagina = 10,
      }) async {
    final texto = termo.trim();

    if (texto.isEmpty) {
      return carregarObras(
        pagina: pagina,
        porPagina: porPagina,
      );
    }

    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select(_campos)
        .or(
      'titulo.ilike.%$texto%,autor.ilike.%$texto%,descricao.ilike.%$texto%',
    )
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(item))
        .toList();
  }

  // ============================================================
  // CARREGAR POR CATEGORIA
  // ============================================================

  Future<List<Obra>> carregarPorCategoria(
      String categoria, {
        int pagina = 1,
        int porPagina = 10,
      }) async {
    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select(_campos)
        .eq('categoria', categoria)
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(item))
        .toList();
  }

  // ============================================================
  // CARREGAR POR AUTOR
  // ============================================================

  Future<List<Obra>> carregarPorAutor(
      String autor, {
        int pagina = 1,
        int porPagina = 10,
      }) async {
    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select(_campos)
        .ilike('autor', '%${autor.trim()}%')
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(item))
        .toList();
  }

  // ============================================================
  // CARREGAR POR ANO
  // ============================================================

  Future<List<Obra>> carregarPorAno(
      int ano, {
        int pagina = 1,
        int porPagina = 10,
      }) async {
    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select(_campos)
        .eq('ano_obra', ano)
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(item))
        .toList();
  }

  // ============================================================
  // CARREGAR MINHAS OBRAS
  // ============================================================

  Future<List<Obra>> carregarMinhasObras({
    int pagina = 1,
    int porPagina = 10,
  }) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return [];
    }

    final inicio = (pagina - 1) * porPagina;
    final fim = inicio + porPagina - 1;

    final resposta = await _supabase
        .from(_tabela)
        .select(_campos)
        .eq('user_id', usuario.id)
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(item))
        .toList();
  }

  // ============================================================
  // INSERIR
  // ============================================================

  Future<Obra> inserir(Obra obra) async {
    final dados = {
      'id': obra.id,
      'titulo': obra.titulo,
      'descricao': obra.descricao,
      'autor': obra.autor,
      'categoria': obra.categoria,
      'url_documento': obra.urlDocumento,
      'ano_obra': obra.anoObra,
      'data_publicacao': obra.dataPublicacao.toIso8601String(),
      'user_id': obra.userId,
    };

    final resposta = await _supabase
        .from(_tabela)
        .insert(dados)
        .select(_campos)
        .single();

    return Obra.fromMap(resposta);
  }

  // ============================================================
  // ATUALIZAR
  // ============================================================

  Future<Obra> atualizar(Obra obra) async {
    final dados = {
      'titulo': obra.titulo,
      'descricao': obra.descricao,
      'autor': obra.autor,
      'categoria': obra.categoria,
      'url_documento': obra.urlDocumento,
      'ano_obra': obra.anoObra,
      'data_publicacao': obra.dataPublicacao.toIso8601String(),
    };

    final resposta = await _supabase
        .from(_tabela)
        .update(dados)
        .eq('id', obra.id)
        .select(_campos)
        .single();

    return Obra.fromMap(resposta);
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<void> excluir(String id) async {
    await _supabase
        .from(_tabela)
        .delete()
        .eq('id', id);
  }

  // ============================================================
  // CONTAR OBRAS
  // ============================================================

  Future<int> contarObras() async {
    final resposta = await _supabase
        .from(_tabela)
        .select('id');

    return (resposta as List).length;
  }

  // ============================================================
  // CONTAR MINHAS OBRAS
  // ============================================================

  Future<int> contarMinhasObras() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      return 0;
    }

    final resposta = await _supabase
        .from(_tabela)
        .select('id')
        .eq('user_id', usuario.id);

    return (resposta as List).length;
  }
}

