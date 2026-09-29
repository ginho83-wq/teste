import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';

class ObrasRepository {
  ObrasRepository._();

  static final ObrasRepository instancia =
  ObrasRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  static const String _campos = '''
    id,
    titulo,
    descricao,
    autor,
    categoria,
    url_documento,
    url_capa,
    ano_obra,
    data_publicacao,
    numero_paginas,
    tamanho_arquivo_bytes,
    hash_pdf,
    user_id,
    created_at,
    updated_at
  ''';

  Future<List<Obra>>
  carregarObras({
    int pagina = 1,
    int limite = 10,
  }) async {
    final inicio = (pagina - 1) * limite;
    final fim = inicio + limite - 1;

    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .order(
      'data_publicacao',
      ascending: false,
    )
        .range(inicio, fim);

    return (resposta as List)
        .map(
          (item) => Obra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
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

  Future<List<Obra>>
  pesquisar(
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
        .order(
      'data_publicacao',
      ascending: false,
    )
        .limit(limite);

    return (resposta as List)
        .map(
          (item) => Obra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<List<Obra>>
  carregarPorCategoria(
      String categoria, {
        int limite = 50,
      }) async {
    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .eq('categoria', categoria)
        .order(
      'data_publicacao',
      ascending: false,
    )
        .limit(limite);

    return (resposta as List)
        .map(
          (item) => Obra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<List<Obra>>
  carregarPorAutor(
      String autor, {
        int limite = 50,
      }) async {
    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .ilike(
      'autor',
      '%${autor.trim()}%',
    )
        .order(
      'data_publicacao',
      ascending: false,
    )
        .limit(limite);

    return (resposta as List)
        .map(
          (item) => Obra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<List<Obra>>
  carregarPorAno(
      int ano, {
        int limite = 50,
      }) async {
    final resposta = await _supabase
        .from('obras')
        .select(_campos)
        .eq('ano_obra', ano)
        .order(
      'data_publicacao',
      ascending: false,
    )
        .limit(limite);

    return (resposta as List)
        .map(
          (item) => Obra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<List<Obra>>
  carregarMinhasObras(
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
        .order(
      'data_publicacao',
      ascending: false,
    )
        .range(inicio, fim);

    return (resposta as List)
        .map(
          (item) => Obra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  // ============================================================
  // VERIFICAR DUPLICADO
  // ============================================================

  Future<bool> existeDuplicado({
    required String titulo,
    required String autor,
    required String nomeArquivo,
    String? hashPdf,
  }) async {
    final tituloLimpo = titulo.trim();
    final autorLimpo = autor.trim();
    final nomeArquivoLimpo =
    _nomeArquivo(nomeArquivo);
    final hashLimpo = hashPdf?.trim() ?? '';

    // ----------------------------------------------------------
    // 1. VERIFICAR HASH DO PDF
    // ----------------------------------------------------------

    if (hashLimpo.isNotEmpty) {
      final respostaHash = await _supabase
          .from('obras')
          .select('id, hash_pdf')
          .eq('hash_pdf', hashLimpo)
          .limit(1);

      if ((respostaHash as List).isNotEmpty) {
        return true;
      }
    }

    // ----------------------------------------------------------
    // 2. VERIFICAR TÍTULO + AUTOR
    // ----------------------------------------------------------

    if (tituloLimpo.isNotEmpty &&
        autorLimpo.isNotEmpty) {
      final respostaTituloAutor =
      await _supabase
          .from('obras')
          .select('id, titulo, autor')
          .ilike(
        'titulo',
        tituloLimpo,
      )
          .ilike(
        'autor',
        autorLimpo,
      )
          .limit(20);

      if ((respostaTituloAutor as List)
          .isNotEmpty) {
        return true;
      }
    }

    // ----------------------------------------------------------
    // 3. VERIFICAR NOME DO PDF
    // ----------------------------------------------------------

    if (nomeArquivoLimpo.isNotEmpty) {
      final respostaArquivo =
      await _supabase
          .from('obras')
          .select('id, url_documento')
          .ilike(
        'url_documento',
        '%/$nomeArquivoLimpo',
      )
          .limit(20);

      if ((respostaArquivo as List)
          .isNotEmpty) {
        return true;
      }
    }

    return false;
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
    if (obra.id.isEmpty) {
      throw Exception(
        'O ID da obra é obrigatório para atualização.',
      );
    }

    final dados = obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

    final resposta = await _supabase
        .from('obras')
        .update(dados)
        .eq('id', obra.id)
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

  Future<int> contarMinhasObras(
      String userId,
      ) async {
    final resposta = await _supabase
        .from('obras')
        .select('id')
        .eq('user_id', userId);

    return (resposta as List).length;
  }

  String _nomeArquivo(String caminho) {
    final caminhoLimpo = caminho.trim();

    final indice =
    caminhoLimpo.lastIndexOf('/');

    if (indice == -1) {
      return caminhoLimpo;
    }

    return caminhoLimpo.substring(
      indice + 1,
    );
  }
}
