import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../services/storage_service.dart';

class ObrasPendentesRepository {
  ObrasPendentesRepository._();

  static final ObrasPendentesRepository instancia =
  ObrasPendentesRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final StorageService _storage =
      StorageService.instancia;

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
    user_id,
    tamanho_arquivo_bytes,
    hash_pdf,
    created_at,
    updated_at
  ''';

  Future<List<ObraPendente>>
  carregarTodas() async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .order(
      'data_publicacao',
      ascending: false,
    );

    return (resposta as List)
        .map(
          (item) => ObraPendente.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<ObraPendente?> carregarPorId(
      String id,
      ) async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq('id', id)
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return ObraPendente.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  Future<List<ObraPendente>>
  carregarDoUsuario(
      String userId,
      ) async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq('user_id', userId)
        .order(
      'data_publicacao',
      ascending: false,
    );

    return (resposta as List)
        .map(
          (item) => ObraPendente.fromMap(
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
      final respostaHash =
      await _supabase
          .from('obras_pendentes')
          .select('id, hash_pdf')
          .eq('hash_pdf', hashLimpo)
          .limit(1);

      if ((respostaHash as List)
          .isNotEmpty) {
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
          .from('obras_pendentes')
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
          .from('obras_pendentes')
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

  // ============================================================
  // INSERIR OBRA PENDENTE
  // ============================================================

  Future<ObraPendente> inserir(
      ObraPendente obra, {
        String? hashPdf,
      }) async {
    final dados = obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

    if (hashPdf != null &&
        hashPdf.trim().isNotEmpty) {
      dados['hash_pdf'] = hashPdf.trim();
    }

    final resposta = await _supabase
        .from('obras_pendentes')
        .insert(dados)
        .select(_campos)
        .single();

    return ObraPendente.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  // ============================================================
  // APROVAR OBRA
  // ============================================================

  Future<Obra> aprovar(
      String id,
      ) async {
    final pendente =
    await carregarPorId(id);

    if (pendente == null) {
      throw Exception(
        'Obra pendente não encontrada.',
      );
    }

    if (pendente.urlDocumento
        .trim()
        .isEmpty) {
      throw Exception(
        'O caminho do arquivo da obra pendente '
            'não foi encontrado.',
      );
    }

    // ==========================================================
    // OBTER HASH DA OBRA PENDENTE
    // ==========================================================

    final respostaHash =
    await _supabase
        .from('obras_pendentes')
        .select('hash_pdf')
        .eq('id', id)
        .maybeSingle();

    final hashPdf =
    respostaHash?['hash_pdf']?.toString();

    // ==========================================================
    // COPIAR PDF
    // ==========================================================

    final caminhoPdfPendente =
        pendente.urlDocumento;

    final caminhoPdfPublicado =
    await _storage
        .copiarDocumentoParaPublicadas(
      caminhoPendente:
      caminhoPdfPendente,
      userId:
      pendente.userId,
      nomeArquivo:
      _nomeArquivo(
        caminhoPdfPendente,
      ),
    );

    final urlPdfPublica =
    _storage.obterUrlPublica(
      caminhoPdfPublicado,
    );

    // ==========================================================
    // COPIAR CAPA
    // ==========================================================

    String? urlCapaPublica;

    if (pendente.urlCapa != null &&
        pendente.urlCapa!
            .trim()
            .isNotEmpty) {
      final caminhoCapaPendente =
      pendente.urlCapa!;

      final caminhoCapaPublicado =
      await _storage
          .copiarCapaParaPublicadas(
        caminhoPendente:
        caminhoCapaPendente,
        userId:
        pendente.userId,
        nomeArquivo:
        _nomeArquivo(
          caminhoCapaPendente,
        ),
      );

      urlCapaPublica =
          _storage.obterUrlCapaPublica(
            caminhoCapaPublicado,
          );
    }

    // ==========================================================
    // CRIAR OBRA PUBLICADA
    // ==========================================================

    final dadosObra =
    <String, dynamic>{
      'titulo':
      pendente.titulo,

      'descricao':
      pendente.descricao,

      'autor':
      pendente.autor,

      'categoria':
      pendente.categoria,

      'url_documento':
      urlPdfPublica,

      'url_capa':
      urlCapaPublica,

      'ano_obra':
      pendente.anoObra,

      'data_publicacao':
      pendente.dataPublicacao
          .toIso8601String(),

      'numero_paginas':
      pendente.numeroPaginas,

      'user_id':
      pendente.userId,

      'tamanho_arquivo_bytes':
      pendente.tamanhoArquivoBytes,

      'hash_pdf':
      hashPdf,
    };

    final resposta =
    await _supabase
        .from('obras')
        .insert(dadosObra)
        .select(_campos)
        .single();

    // ==========================================================
    // REMOVER REGISTO PENDENTE
    // ==========================================================

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq('id', id);

    // ==========================================================
    // REMOVER PDF PENDENTE
    // ==========================================================

    try {
      await _storage
          .removerDocumentoPendente(
        caminhoPdfPendente,
      );
    } catch (_) {}

    // ==========================================================
    // REMOVER CAPA PENDENTE
    // ==========================================================

    if (pendente.urlCapa != null &&
        pendente.urlCapa!
            .trim()
            .isNotEmpty) {
      try {
        await _storage
            .removerCapaPendente(
          pendente.urlCapa!,
        );
      } catch (_) {}
    }

    return Obra.fromMap(
      Map<String, dynamic>.from(
        resposta,
      ),
    );
  }

  // ============================================================
  // REJEITAR
  // ============================================================

  Future<void> rejeitar(
      String id,
      ) async {
    final pendente =
    await carregarPorId(id);

    if (pendente == null) {
      throw Exception(
        'Obra pendente não encontrada.',
      );
    }

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq('id', id);

    if (pendente.urlDocumento
        .trim()
        .isNotEmpty) {
      try {
        await _storage
            .removerDocumentoPendente(
          pendente.urlDocumento,
        );
      } catch (_) {}
    }

    if (pendente.urlCapa != null &&
        pendente.urlCapa!
            .trim()
            .isNotEmpty) {
      try {
        await _storage
            .removerCapaPendente(
          pendente.urlCapa!,
        );
      } catch (_) {}
    }
  }

  Future<void> excluir(
      String id,
      ) async {
    await rejeitar(id);
  }

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
