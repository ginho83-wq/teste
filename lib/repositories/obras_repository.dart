import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../repositories/obras_imagens_repository.dart';
import '../services/imagens_storage_service.dart';
import '../services/storage_service.dart';

class ObrasRepository {
  ObrasRepository._();

  static final ObrasRepository instancia =
  ObrasRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final StorageService _storage =
      StorageService.instancia;

  final ImagensStorageService
  _imagensStorage =
      ImagensStorageService.instancia;

  final ObrasImagensRepository
  _obrasImagensRepository =
      ObrasImagensRepository.instancia;

  static const String _campos = '''
    id,
    titulo,
    descricao,
    autor,
    categoria,
    url_documento,
    ano_obra,
    data_publicacao,
    numero_paginas,
    tamanho_arquivo_bytes,
    conteudo_texto,
    hash_pdf,
    user_id,
    created_at,
    updated_at
  ''';

  // ============================================================
  // CARREGAR OBRAS
  // ============================================================

  Future<List<Obra>> carregarObras({
    int pagina = 1,
    int limite = 10,
  }) async {
    final inicio =
        (pagina - 1) * limite;

    final fim =
        inicio + limite - 1;

    final resposta =
    await _supabase
        .from('obras')
        .select(_campos)
        .order(
      'data_publicacao',
      ascending: false,
    )
        .range(
      inicio,
      fim,
    );

    return (resposta as List)
        .map(
          (item) =>
          Obra.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // CARREGAR TODAS
  // ============================================================

  Future<List<Obra>> carregarTodas() async {
    final resposta =
    await _supabase
        .from('obras')
        .select(_campos)
        .order(
      'data_publicacao',
      ascending: false,
    );

    return (resposta as List)
        .map(
          (item) =>
          Obra.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // CARREGAR POR ID
  // ============================================================

  Future<Obra?> carregarPorId(
      String id,
      ) async {
    final resposta =
    await _supabase
        .from('obras')
        .select(_campos)
        .eq('id', id)
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return Obra.fromMap(
      Map<String, dynamic>.from(
        resposta,
      ),
    );
  }

  // ============================================================
  // PESQUISAR
  // ============================================================

  Future<List<Obra>> pesquisar(
      String termo, {
        int limite = 50,
      }) async {
    final termoLimpo =
    termo.trim();

    if (termoLimpo.isEmpty) {
      return carregarObras(
        pagina: 1,
        limite: limite,
      );
    }

    final resposta =
    await _supabase
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
          (item) =>
          Obra.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // CARREGAR POR CATEGORIA
  // ============================================================

  Future<List<Obra>>
  carregarPorCategoria(
      String categoria, {
        int limite = 50,
      }) async {
    final resposta =
    await _supabase
        .from('obras')
        .select(_campos)
        .eq(
      'categoria',
      categoria,
    )
        .order(
      'data_publicacao',
      ascending: false,
    )
        .limit(limite);

    return (resposta as List)
        .map(
          (item) =>
          Obra.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // CARREGAR POR AUTOR
  // ============================================================

  Future<List<Obra>> carregarPorAutor(
      String autor, {
        int limite = 50,
      }) async {
    final autorLimpo =
    autor.trim();

    final resposta =
    await _supabase
        .from('obras')
        .select(_campos)
        .ilike(
      'autor',
      '%$autorLimpo%',
    )
        .order(
      'data_publicacao',
      ascending: false,
    )
        .limit(limite);

    return (resposta as List)
        .map(
          (item) =>
          Obra.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // CARREGAR POR ANO
  // ============================================================

  Future<List<Obra>> carregarPorAno(
      int ano, {
        int limite = 50,
      }) async {
    final resposta =
    await _supabase
        .from('obras')
        .select(_campos)
        .eq(
      'ano_obra',
      ano,
    )
        .order(
      'data_publicacao',
      ascending: false,
    )
        .limit(limite);

    return (resposta as List)
        .map(
          (item) =>
          Obra.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // MINHAS OBRAS
  // ============================================================

  Future<List<Obra>>
  carregarMinhasObras(
      String userId, {
        int pagina = 1,
        int limite = 10,
      }) async {
    final inicio =
        (pagina - 1) * limite;

    final fim =
        inicio + limite - 1;

    final resposta =
    await _supabase
        .from('obras')
        .select(_campos)
        .eq(
      'user_id',
      userId,
    )
        .order(
      'data_publicacao',
      ascending: false,
    )
        .range(
      inicio,
      fim,
    );

    return (resposta as List)
        .map(
          (item) =>
          Obra.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // DUPLICADO
  // ============================================================

  Future<bool> existeDuplicado({
    required String titulo,
    required String autor,
    required String nomeArquivo,
    String? hashPdf,
  }) async {
    final tituloLimpo =
    titulo.trim();

    final autorLimpo =
    autor.trim();

    final nomeArquivoLimpo =
    _nomeArquivo(nomeArquivo);

    final hashLimpo =
        hashPdf?.trim() ?? '';

    if (hashLimpo.isNotEmpty) {
      final respostaHash =
      await _supabase
          .from('obras')
          .select(
        'id, hash_pdf',
      )
          .eq(
        'hash_pdf',
        hashLimpo,
      )
          .limit(1);

      if ((respostaHash as List)
          .isNotEmpty) {
        return true;
      }
    }

    if (tituloLimpo.isNotEmpty &&
        autorLimpo.isNotEmpty) {
      final respostaTituloAutor =
      await _supabase
          .from('obras')
          .select(
        'id, titulo, autor',
      )
          .ilike(
        'titulo',
        tituloLimpo,
      )
          .ilike(
        'autor',
        autorLimpo,
      )
          .limit(20);

      if ((respostaTituloAutor
      as List)
          .isNotEmpty) {
        return true;
      }
    }

    if (nomeArquivoLimpo.isNotEmpty) {
      final respostaArquivo =
      await _supabase
          .from('obras')
          .select(
        'id, url_documento',
      )
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

  // ============================================================
  // INSERIR
  // ============================================================

  Future<Obra> inserir(
      Obra obra,
      ) async {
    final dados =
    obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

    final resposta =
    await _supabase
        .from('obras')
        .insert(dados)
        .select(_campos)
        .single();

    return Obra.fromMap(
      Map<String, dynamic>.from(
        resposta,
      ),
    );
  }

  // ============================================================
  // ATUALIZAR
  // ============================================================

  Future<Obra> atualizar(
      Obra obra,
      ) async {
    if (obra.id.isEmpty) {
      throw Exception(
        'O ID da obra é obrigatório para atualização.',
      );
    }

    final dados =
    obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

    final resposta =
    await _supabase
        .from('obras')
        .update(dados)
        .eq(
      'id',
      obra.id,
    )
        .select(_campos)
        .single();

    return Obra.fromMap(
      Map<String, dynamic>.from(
        resposta,
      ),
    );
  }

  // ============================================================
  // EXCLUIR REGISTO
  // ============================================================

  Future<void> excluir(
      String id,
      ) async {
    await _supabase
        .from('obras')
        .delete()
        .eq(
      'id',
      id,
    );
  }

  // ============================================================
  // EXCLUIR OBRA PUBLICADA COMPLETAMENTE
  // ============================================================

  Future<void> excluirPublicada(
      String id,
      ) async {
    if (id.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    final obra =
    await carregarPorId(id);

    if (obra == null) {
      throw Exception(
        'Obra publicada não encontrada.',
      );
    }

    // ==========================================================
    // 1. CARREGAR IMAGENS
    // ==========================================================

    final imagens =
    await _obrasImagensRepository
        .carregarPorObra(
      id,
    );

    // ==========================================================
    // 2. REMOVER IMAGENS DO STORAGE
    // ==========================================================

    for (final imagem
    in imagens) {
      final caminho =
      _extrairCaminhoStorage(
        imagem.urlImagem,
        ImagensStorageService
            .bucketImagens,
      );

      if (caminho.isEmpty ||
          caminho.startsWith(
            'http://',
          ) ||
          caminho.startsWith(
            'https://',
          )) {
        continue;
      }

      try {
        await _imagensStorage
            .removerImagem(
          caminho,
        );
      } catch (_) {}
    }

    // ==========================================================
    // 3. REMOVER REGISTOS DAS IMAGENS
    // ==========================================================

    try {
      await _obrasImagensRepository
          .eliminarPorObra(
        id,
      );
    } catch (_) {}

    // ==========================================================
    // 4. REMOVER PDF
    // ==========================================================

    if (obra.urlDocumento
        .trim()
        .isNotEmpty) {
      final caminhoPdf =
      _extrairCaminhoStorage(
        obra.urlDocumento,
        StorageService
            .bucketObras,
      );

      try {
        await _storage
            .removerDocumentoPublicado(
          caminhoPdf,
        );
      } catch (_) {}
    }

    // ==========================================================
    // 5. REMOVER OBRA
    // ==========================================================

    await _supabase
        .from('obras')
        .delete()
        .eq(
      'id',
      id,
    );
  }

  // ============================================================
  // CONTAR OBRAS
  // ============================================================

  Future<int> contarObras() async {
    final resposta =
    await _supabase
        .from('obras')
        .select('id');

    return (resposta as List).length;
  }

  // ============================================================
  // CONTAR MINHAS OBRAS
  // ============================================================

  Future<int> contarMinhasObras(
      String userId,
      ) async {
    final resposta =
    await _supabase
        .from('obras')
        .select('id')
        .eq(
      'user_id',
      userId,
    );

    return (resposta as List).length;
  }

  // ============================================================
  // EXTRAIR CAMINHO DO STORAGE
  // ============================================================

  String _extrairCaminhoStorage(
      String valor,
      String bucket,
      ) {
    final valorLimpo =
    valor.trim();

    if (valorLimpo.isEmpty) {
      return '';
    }

    if (!valorLimpo.startsWith(
      'http://',
    ) &&
        !valorLimpo.startsWith(
          'https://',
        )) {
      return valorLimpo;
    }

    final marcador =
        '/storage/v1/object/public/$bucket/';

    final indice =
    valorLimpo.indexOf(
      marcador,
    );

    if (indice != -1) {
      return Uri.decodeComponent(
        valorLimpo.substring(
          indice +
              marcador.length,
        ),
      );
    }

    final marcadorAlternativo =
        '/storage/v1/object/$bucket/';

    final indiceAlternativo =
    valorLimpo.indexOf(
      marcadorAlternativo,
    );

    if (indiceAlternativo != -1) {
      var caminho =
      valorLimpo.substring(
        indiceAlternativo +
            marcadorAlternativo.length,
      );

      final indiceQuery =
      caminho.indexOf('?');

      if (indiceQuery != -1) {
        caminho =
            caminho.substring(
              0,
              indiceQuery,
            );
      }

      return Uri.decodeComponent(
        caminho,
      );
    }

    return valorLimpo;
  }

  // ============================================================
  // NOME DO ARQUIVO
  // ============================================================

  String _nomeArquivo(
      String caminho,
      ) {
    final caminhoLimpo =
    caminho.trim();

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
