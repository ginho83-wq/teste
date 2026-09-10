import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';

class ObrasRepository {
  ObrasRepository._();

  static final ObrasRepository instancia = ObrasRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

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

  Future<List<Obra>> carregarObras({
    int pagina = 1,
    int limite = 10,
  }) async {
    final inicio = (pagina - 1) * limite;
    final fim = inicio + limite - 1;

    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Obra?> carregarPorId(String id) async {
    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .eq('id', id)
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return Obra.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  Future<List<Obra>> pesquisar(
      String termo, {
        int limite = 50,
      }) async {
    final termoLimpo = termo.trim();

    if (termoLimpo.isEmpty) {
      return carregarObras(
        pagina: 1,
        limite: limite,
      );
    }

    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .or(
      'titulo.ilike.%$termoLimpo%,'
          'autor.ilike.%$termoLimpo%,'
          'descricao.ilike.%$termoLimpo%,'
          'categoria.ilike.%$termoLimpo%',
    )
        .order('data_publicacao', ascending: false)
        .limit(limite);

    return (resposta as List)
        .map((item) => Obra.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Obra>> carregarPorCategoria(
      String categoria, {
        int limite = 50,
      }) async {
    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .eq('categoria', categoria)
        .order('data_publicacao', ascending: false)
        .limit(limite);

    return (resposta as List)
        .map((item) => Obra.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Obra>> carregarPorAutor(
      String autor, {
        int limite = 50,
      }) async {
    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .ilike('autor', '%${autor.trim()}%')
        .order('data_publicacao', ascending: false)
        .limit(limite);

    return (resposta as List)
        .map((item) => Obra.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Obra>> carregarPorAno(
      int ano, {
        int limite = 50,
      }) async {
    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .eq('ano_obra', ano)
        .order('data_publicacao', ascending: false)
        .limit(limite);

    return (resposta as List)
        .map((item) => Obra.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Obra>> carregarMinhasObras(
      String userId, {
        int pagina = 1,
        int limite = 10,
      }) async {
    final inicio = (pagina - 1) * limite;
    final fim = inicio + limite - 1;

    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .eq('user_id', userId)
        .order('data_publicacao', ascending: false)
        .range(inicio, fim);

    return (resposta as List)
        .map((item) => Obra.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Obra> inserir(Obra obra) async {
    final dados = obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

    final resposta = await _supabase
        .from('obras')
        .insert(dados)
        .select(_campos)
        .single();

    return Obra.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  Future<Obra> atualizar(Obra obra) async {
    if (obra.id == null || obra.id!.isEmpty) {
      throw Exception('O ID da obra é obrigatório para atualização.');
    }

    final dados = obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

    final resposta = await _supabase
        .from('obras')
        .update(dados)
        .eq('id', obra.id!)
        .select(_campos)
        .single();

    return Obra.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  Future<void> excluir(String id) async {
    await _supabase
        .from('obras')
        .delete()
        .eq('id', id);
  }

  Future<int> contarObras() async {
    final resposta = await _supabase
        .from('obras')
        .select('id');

    return (resposta as List).length;
  }

  Future<int> contarMinhasObras(String userId) async {
    final resposta = await _supabase
        .from('obras')
        .select('id')
        .eq('user_id', userId);

    return (resposta as List).length;
  }
}
