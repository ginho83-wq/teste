import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/obra.dart';
import '../models/obra_imagem.dart';
import '../models/obra_pendente.dart';
import '../services/imagens_storage_service.dart';
import '../services/storage_service.dart';
import 'obras_imagens_repository.dart';

class ObrasPendentesRepository {
  ObrasPendentesRepository._();

  static final ObrasPendentesRepository instancia =
  ObrasPendentesRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  final StorageService _storage =
      StorageService.instancia;

  final ImagensStorageService _imagensStorage =
      ImagensStorageService.instancia;

  final ObrasImagensRepository _imagensRepository =
      ObrasImagensRepository.instancia;

  final Uuid _uuid = const Uuid();

  // ============================================================
  // CAMPOS
  // ============================================================

  static const String _campos = '''
    id,
    titulo,
    descricao,
    conteudo_texto,
    autor,
    categoria,
    url_documento,
    ano_obra,
    data_publicacao,
    numero_paginas,
    user_id,
    tamanho_arquivo_bytes,
    hash_pdf,
    created_at,
    updated_at
  ''';

  // ============================================================
  // CARREGAR TODAS
  // ============================================================

  Future<List<ObraPendente>> carregarTodas() async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .order(
      'created_at',
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
  // CARREGAR POR ID
  // ============================================================

  Future<ObraPendente?> carregarPorId(
      String id,
      ) async {
    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      return null;
    }

    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq('id', idLimpo)
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return ObraPendente.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  // ============================================================
  // CARREGAR DO USUÁRIO
  // ============================================================

  Future<List<ObraPendente>> carregarDoUsuario(
      String userId,
      ) async {
    final idLimpo = userId.trim();

    if (idLimpo.isEmpty) {
      return [];
    }

    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq('user_id', idLimpo)
        .order(
      'created_at',
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

  Future<bool> existeDuplicado(
      String hashPdf,
      ) async {
    final hash = hashPdf.trim();

    if (hash.isEmpty) {
      return false;
    }

    final publicado = await _supabase
        .from('obras')
        .select('id')
        .eq('hash_pdf', hash)
        .maybeSingle();

    if (publicado != null) {
      return true;
    }

    final pendente = await _supabase
        .from('obras_pendentes')
        .select('id')
        .eq('hash_pdf', hash)
        .maybeSingle();

    return pendente != null;
  }

  // ============================================================
  // INSERIR OBRA PENDENTE
  // ============================================================

  Future<ObraPendente> inserir(
      ObraPendente obra,
      ) async {
    final dados = obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

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
  // INSERIR IMAGEM PENDENTE
  // ============================================================

  Future<ObraImagem> inserirImagemPendente({
    required String obraPendenteId,
    required String caminhoImagem,
    String? legenda,
    String? fonte,
    String posicao = 'dentro_conteudo',
    int ordem = 1,
  }) async {
    final idPendente =
    obraPendenteId.trim();

    final caminhoLimpo =
    caminhoImagem.trim();

    final legendaLimpa =
    legenda?.trim();

    final fonteLimpa =
    fonte?.trim();

    if (idPendente.isEmpty) {
      throw Exception(
        'obra_pendente_id não pode estar vazio.',
      );
    }

    if (caminhoLimpo.isEmpty) {
      throw Exception(
        'caminho_imagem não pode estar vazio.',
      );
    }

    print('================================================');
    print(
      '[DIAGNÓSTICO IMAGEM] INSERIR IMAGEM PENDENTE',
    );
    print(
      '[DIAGNÓSTICO IMAGEM] obra_pendente_id: '
          '$idPendente',
    );
    print(
      '[DIAGNÓSTICO IMAGEM] caminho_imagem: '
          '$caminhoLimpo',
    );
    print(
      '[DIAGNÓSTICO IMAGEM] legenda: '
          '$legendaLimpa',
    );
    print(
      '[DIAGNÓSTICO IMAGEM] fonte: '
          '$fonteLimpa',
    );
    print(
      '[DIAGNÓSTICO IMAGEM] posicao: '
          '$posicao',
    );
    print(
      '[DIAGNÓSTICO IMAGEM] ordem: '
          '$ordem',
    );

    try {
      final dados = <String, dynamic>{
        'obra_pendente_id': idPendente,
        'caminho_imagem': caminhoLimpo,
        'legenda': legendaLimpa?.isEmpty == true
            ? null
            : legendaLimpa,
        'fonte': fonteLimpa?.isEmpty == true
            ? null
            : fonteLimpa,
        'posicao': posicao,
        'ordem': ordem,
      };

      final resposta = await _supabase
          .from('obras_pendentes_imagens')
          .insert(dados)
          .select('''
            id,
            obra_pendente_id,
            caminho_imagem,
            legenda,
            fonte,
            posicao,
            ordem,
            created_at
          ''')
          .single();

      print(
        '[DIAGNÓSTICO IMAGEM] IMAGEM PENDENTE '
            'GRAVADA COM SUCESSO',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] Dados retornados: '
            '$resposta',
      );

      print('================================================');

      return ObraImagem.fromMap(
        Map<String, dynamic>.from(resposta),
      );
    } on PostgrestException catch (e) {
      print(
        '[DIAGNÓSTICO IMAGEM] ERRO AO INSERIR '
            'IMAGEM PENDENTE',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] code: ${e.code}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] message: ${e.message}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] details: ${e.details}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] hint: ${e.hint}',
      );

      print('================================================');

      rethrow;
    }
  }

  // ============================================================
  // CARREGAR IMAGENS PENDENTES
  // ============================================================

  Future<List<ObraImagem>> carregarImagensPendentes(
      String obraPendenteId,
      ) async {
    final idLimpo =
    obraPendenteId.trim();

    if (idLimpo.isEmpty) {
      return [];
    }

    print('================================================');
    print(
      '[DIAGNÓSTICO IMAGEM] CONSULTANDO '
          'obras_pendentes_imagens...',
    );

    print(
      '[DIAGNÓSTICO IMAGEM] obra_pendente_id: '
          '$idLimpo',
    );

    final usuarioAtual =
        _supabase.auth.currentUser;

    print(
      '[DIAGNÓSTICO IMAGEM] auth.uid: '
          '${usuarioAtual?.id}',
    );

    print(
      '[DIAGNÓSTICO IMAGEM] auth.email: '
          '${usuarioAtual?.email}',
    );

    print(
      '[DIAGNÓSTICO IMAGEM] sessão existe: '
          '${_supabase.auth.currentSession != null}',
    );

    if (usuarioAtual == null) {
      throw Exception(
        'Não existe sessão autenticada para '
            'carregar as imagens pendentes.',
      );
    }

    try {
      final resposta = await _supabase
          .from('obras_pendentes_imagens')
          .select('''
            id,
            obra_pendente_id,
            caminho_imagem,
            legenda,
            fonte,
            posicao,
            ordem,
            created_at
          ''')
          .eq(
        'obra_pendente_id',
        idLimpo,
      )
          .order(
        'ordem',
        ascending: true,
      );

      final lista = (resposta as List)
          .map(
            (item) => ObraImagem.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      print(
        '[DIAGNÓSTICO IMAGEM] Imagens pendentes '
            'encontradas: ${lista.length}',
      );

      for (final imagem in lista) {
        print(
          '[DIAGNÓSTICO IMAGEM] '
              'id=${imagem.id} | '
              'obra_pendente_id=${imagem.obraId} | '
              'caminho=${imagem.urlImagem} | '
              'legenda=${imagem.legenda} | '
              'fonte=${imagem.fonte} | '
              'posicao=${imagem.posicao} | '
              'ordem=${imagem.ordem}',
        );
      }

      print('================================================');

      return lista;
    } on PostgrestException catch (e) {
      print(
        '[DIAGNÓSTICO IMAGEM] ERRO AO CONSULTAR '
            'obras_pendentes_imagens',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] code: ${e.code}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] message: ${e.message}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] details: ${e.details}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] hint: ${e.hint}',
      );

      print('================================================');

      rethrow;
    }
  }

  // ============================================================
  // ELIMINAR IMAGENS PENDENTES
  // ============================================================

  Future<void> eliminarImagensPendentes(
      String obraPendenteId,
      ) async {
    final idLimpo =
    obraPendenteId.trim();

    if (idLimpo.isEmpty) {
      return;
    }

    print('================================================');
    print(
      '[DIAGNÓSTICO IMAGEM] A REMOVER '
          'IMAGENS PENDENTES...',
    );

    final imagens =
    await carregarImagensPendentes(
      idLimpo,
    );

    for (final imagem in imagens) {
      try {
        final caminho =
            imagem.urlImagem;

        if (caminho != null &&
            caminho.trim().isNotEmpty) {
          await _imagensStorage
              .removerImagemPendente(
            caminho,
          );
        }
      } catch (e) {
        print(
          '[DIAGNÓSTICO IMAGEM] Erro ao remover '
              'arquivo pendente: $e',
        );
      }
    }

    await _supabase
        .from('obras_pendentes_imagens')
        .delete()
        .eq(
      'obra_pendente_id',
      idLimpo,
    );

    print(
      '[DIAGNÓSTICO IMAGEM] Imagens pendentes '
          'removidas.',
    );

    print('================================================');
  }

  // ============================================================
  // APROVAR OBRA
  // ============================================================

  Future<Obra> aprovar(
      String obraPendenteId,
      ) async {
    final idLimpo =
    obraPendenteId.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra pendente inválido.',
      );
    }

    print('================================================');
    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] INÍCIO DA '
          'APROVAÇÃO',
    );
    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] ID pendente: '
          '$idLimpo',
    );
    print('================================================');

    // ==========================================================
    // SESSÃO
    // ==========================================================

    final usuarioAtual =
        _supabase.auth.currentUser;

    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] usuário '
          'autenticado: ${usuarioAtual?.id}',
    );

    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] sessão existe: '
          '${_supabase.auth.currentSession != null}',
    );

    if (usuarioAtual == null) {
      throw Exception(
        'A aprovação não pode continuar porque '
            'não existe uma sessão autenticada.',
      );
    }

    // ==========================================================
    // CARREGAR PENDENTE
    // ==========================================================

    final pendente =
    await carregarPorId(
      idLimpo,
    );

    if (pendente == null) {
      throw Exception(
        'Obra pendente não encontrada: '
            '$idLimpo',
      );
    }

    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] Obra pendente '
          'encontrada: ${pendente.id}',
    );

    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] user_id: '
          '${pendente.userId}',
    );

    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] url_documento: '
          '${pendente.urlDocumento}',
    );

    print(
      '[DIAGNÓSTICO PUBLICAÇÃO] hash_pdf: '
          '${pendente.hashPdf}',
    );

    // ==========================================================
    // HASH
    // ==========================================================

    final hashPdf =
    pendente.hashPdf?.trim();

    if (hashPdf != null &&
        hashPdf.isNotEmpty) {
      final duplicado = await _supabase
          .from('obras')
          .select('id')
          .eq(
        'hash_pdf',
        hashPdf,
      )
          .maybeSingle();

      if (duplicado != null) {
        throw Exception(
          'Esta obra já existe no acervo.',
        );
      }
    }

    // ==========================================================
    // IMAGENS PENDENTES
    // ==========================================================

    final imagensPendentes =
    await carregarImagensPendentes(
      idLimpo,
    );

    print('================================================');
    print(
      '[DIAGNÓSTICO IMAGEM] RESUMO ANTES DA '
          'PUBLICAÇÃO',
    );

    print(
      '[DIAGNÓSTICO IMAGEM] Obra pendente: '
          '$idLimpo',
    );

    print(
      '[DIAGNÓSTICO IMAGEM] Total de imagens '
          'pendentes: ${imagensPendentes.length}',
    );

    print('================================================');

    // ==========================================================
    // PDF
    // ==========================================================

    final caminhoPdfPendente =
    pendente.urlDocumento.trim();

    if (caminhoPdfPendente.isEmpty) {
      throw Exception(
        'A obra pendente não possui caminho do PDF.',
      );
    }

    final nomeArquivoPdf =
    _nomeArquivo(
      caminhoPdfPendente,
    );

    bool pdfCopiado = false;

    String? caminhoPdfPublicado;

    String? obraPublicadaId;

    final imagensPublicadas =
    <String>[];

    try {
      // ========================================================
      // COPIAR PDF
      // ========================================================

      print('================================================');
      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] COPIANDO PDF...',
      );

      caminhoPdfPublicado =
      await _storage
          .copiarDocumentoParaPublicadas(
        caminhoPendente:
        caminhoPdfPendente,
        userId:
        pendente.userId,
        nomeArquivo:
        nomeArquivoPdf,
      );

      pdfCopiado = true;

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] PDF COPIADO '
            'COM SUCESSO',
      );

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] caminho '
            'publicado: $caminhoPdfPublicado',
      );

      // ========================================================
      // URL PÚBLICA
      // ========================================================

      final urlDocumento =
      _storage.obterUrlPublica(
        caminhoPdfPublicado,
      );

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] URL pública '
            'do PDF: $urlDocumento',
      );

      // ========================================================
      // CRIAR OBRA PUBLICADA
      // ========================================================

      final dadosObra =
      <String, dynamic>{
        'titulo':
        pendente.titulo,

        'descricao':
        pendente.descricao,

        'conteudo_texto':
        pendente.conteudoTexto,

        'autor':
        pendente.autor,

        'categoria':
        pendente.categoria,

        'url_documento':
        urlDocumento,

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
        pendente.hashPdf,
      };

      final respostaObra =
      await _supabase
          .from('obras')
          .insert(dadosObra)
          .select()
          .single();

      final obra =
      Obra.fromMap(
        Map<String, dynamic>.from(
          respostaObra,
        ),
      );

      obraPublicadaId =
          obra.id;

      print('================================================');
      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] OBRA CRIADA',
      );

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] obra publicada '
            'ID: ${obra.id}',
      );

      print('================================================');

      // ========================================================
      // SECÇÕES
      // ========================================================

      await _transferirSecoes(
        obra,
      );

      // ========================================================
      // IMAGENS
      // ========================================================

      print('================================================');
      print(
        '[DIAGNÓSTICO IMAGEM] INICIANDO '
            'TRANSFERÊNCIA',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] Quantidade esperada: '
            '${imagensPendentes.length}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] obra publicada: '
            '${obra.id}',
      );

      print('================================================');

      for (
      final imagemPendente
      in imagensPendentes
      ) {
        final caminhoPendente =
        imagemPendente.urlImagem
            ?.trim();

        if (caminhoPendente == null ||
            caminhoPendente.isEmpty) {
          throw Exception(
            'Imagem pendente ${imagemPendente.id} '
                'não possui caminho válido.',
          );
        }

        print('------------------------------------------------');

        print(
          '[DIAGNÓSTICO IMAGEM] TRANSFERINDO '
              'IMAGEM',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] ID pendente: '
              '${imagemPendente.id}',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] caminho pendente: '
              '$caminhoPendente',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] legenda: '
              '${imagemPendente.legenda}',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] fonte: '
              '${imagemPendente.fonte}',
        );

        // ======================================================
        // NOME DA IMAGEM
        // ======================================================

        final nomeArquivoImagem =
        _nomeArquivo(
          caminhoPendente,
        );

        print(
          '[DIAGNÓSTICO IMAGEM] nome arquivo: '
              '$nomeArquivoImagem',
        );

        // ======================================================
        // COPIAR IMAGEM
        // ======================================================

        final caminhoPublicado =
        await _imagensStorage
            .copiarImagemParaPublicada(
          caminhoPendente:
          caminhoPendente,
          obraId:
          obra.id,
          nomeArquivo:
          nomeArquivoImagem,
        );

        print(
          '[DIAGNÓSTICO IMAGEM] caminho publicado: '
              '$caminhoPublicado',
        );

        imagensPublicadas.add(
          caminhoPublicado,
        );

        // ======================================================
        // URL PÚBLICA
        // ======================================================

        final urlImagem =
        _imagensStorage
            .obterUrlPublica(
          caminhoPublicado,
        );

        print(
          '[DIAGNÓSTICO IMAGEM] URL pública: '
              '$urlImagem',
        );

        if (urlImagem.trim().isEmpty) {
          throw Exception(
            'A URL pública da imagem ficou vazia.',
          );
        }

        // ======================================================
        // CRIAR REGISTRO
        //
        // AQUI ESTÁ A ALTERAÇÃO PRINCIPAL:
        // fonte também é transferida.
        // ======================================================

        final imagemPublicada =
        ObraImagem(
          id:
          _uuid.v4(),

          obraId:
          obra.id,

          urlImagem:
          urlImagem,

          legenda:
          imagemPendente.legenda,

          fonte:
          imagemPendente.fonte,

          posicao:
          imagemPendente.posicao,

          ordem:
          imagemPendente.ordem,
        );

        print(
          '[DIAGNÓSTICO IMAGEM] Inserindo em '
              'teste_imagens...',
        );

        final imagemGravada =
        await _imagensRepository
            .inserir(
          imagemPublicada,
        );

        print(
          '[DIAGNÓSTICO IMAGEM] IMAGEM INSERIDA '
              'EM teste_imagens',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] ID publicado: '
              '${imagemGravada.id}',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] obra_id: '
              '${imagemGravada.obraId}',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] url_imagem: '
              '${imagemGravada.urlImagem}',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] legenda: '
              '${imagemGravada.legenda}',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] fonte: '
              '${imagemGravada.fonte}',
        );

        // ======================================================
        // VALIDAR OBRA
        // ======================================================

        if (imagemGravada.obraId !=
            obra.id) {
          throw Exception(
            'ERRO CRÍTICO: imagem publicada '
                'ficou associada à obra errada.',
          );
        }

        // ======================================================
        // CONFIRMAR ID
        // ======================================================

        if (imagemGravada.id == null ||
            imagemGravada.id!
                .trim()
                .isEmpty) {
          throw Exception(
            'ERRO CRÍTICO: imagem gravada '
                'não possui ID.',
          );
        }

        // ======================================================
        // CONFIRMAR BANCO
        //
        // Agora também confirma legenda e fonte.
        // ======================================================

        final confirmacao =
        await _supabase
            .from('teste_imagens')
            .select('''
                  id,
                  obra_id,
                  url_imagem,
                  legenda,
                  fonte,
                  posicao,
                  ordem
                ''')
            .eq(
          'id',
          imagemGravada.id!,
        )
            .maybeSingle();

        if (confirmacao == null) {
          throw Exception(
            'ERRO CRÍTICO: imagem inserida não '
                'foi encontrada em teste_imagens.',
          );
        }

        print(
          '[DIAGNÓSTICO IMAGEM] CONFIRMAÇÃO '
              'NO BANCO OK',
        );

        print(
          '[DIAGNÓSTICO IMAGEM] registro: '
              '$confirmacao',
        );

        print('------------------------------------------------');
      }

      // ========================================================
      // CONFIRMAÇÃO FINAL DAS IMAGENS
      // ========================================================

      final imagensFinais =
      await _imagensRepository
          .carregarPorObra(
        obra.id,
      );

      print('================================================');
      print(
        '[DIAGNÓSTICO IMAGEM] CONFIRMAÇÃO FINAL',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] Esperadas: '
            '${imagensPendentes.length}',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] Encontradas: '
            '${imagensFinais.length}',
      );

      if (imagensFinais.length !=
          imagensPendentes.length) {
        throw Exception(
          'ERRO CRÍTICO: nem todas as imagens '
              'foram transferidas para a obra publicada. '
              'Esperadas: ${imagensPendentes.length}; '
              'encontradas: ${imagensFinais.length}.',
        );
      }

      print(
        '[DIAGNÓSTICO IMAGEM] TODAS AS IMAGENS '
            'FORAM REGISTADAS.',
      );

      print(
        '[DIAGNÓSTICO IMAGEM] TRANSFERÊNCIA '
            'CONCLUÍDA COM SUCESSO.',
      );

      print('================================================');

      // ========================================================
      // REMOVER IMAGENS PENDENTES
      // ========================================================

      await eliminarImagensPendentes(
        idLimpo,
      );

      // ========================================================
      // REMOVER OBRA PENDENTE
      // ========================================================

      await _supabase
          .from('obras_pendentes')
          .delete()
          .eq(
        'id',
        idLimpo,
      );

      print('================================================');
      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] OBRA APROVADA',
      );

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] Obra publicada: '
            '${obra.id}',
      );

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] Imagens transferidas: '
            '${imagensFinais.length}',
      );

      print('================================================');

      return obra;
    } catch (e) {
      // ========================================================
      // ROLLBACK
      // ========================================================

      print('================================================');
      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] ERRO DURANTE '
            'APROVAÇÃO',
      );

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] $e',
      );

      print(
        '[DIAGNÓSTICO PUBLICAÇÃO] INICIANDO '
            'ROLLBACK...',
      );

      print('================================================');

      // ========================================================
      // REMOVER REGISTROS DAS IMAGENS
      // ========================================================

      if (obraPublicadaId != null) {
        try {
          await _supabase
              .from('teste_imagens')
              .delete()
              .eq(
            'obra_id',
            obraPublicadaId,
          );
        } catch (erroImagens) {
          print(
            '[ROLLBACK] Erro ao remover registros '
                'de teste_imagens: $erroImagens',
          );
        }

        // ======================================================
        // REMOVER SECÇÕES
        // ======================================================

        try {
          await _supabase
              .from('teste_secoes')
              .delete()
              .eq(
            'obra_id',
            obraPublicadaId,
          );
        } catch (erroSecoes) {
          print(
            '[ROLLBACK] Erro ao remover secções: '
                '$erroSecoes',
          );
        }

        // ======================================================
        // REMOVER OBRA
        // ======================================================

        try {
          await _supabase
              .from('obras')
              .delete()
              .eq(
            'id',
            obraPublicadaId,
          );
        } catch (erroObra) {
          print(
            '[ROLLBACK] Erro ao remover obra '
                'publicada: $erroObra',
          );
        }
      }

      // ========================================================
      // REMOVER IMAGENS PUBLICADAS DO STORAGE
      // ========================================================

      for (
      final caminho
      in imagensPublicadas
      ) {
        try {
          await _imagensStorage
              .removerImagem(
            caminho,
          );
        } catch (erroStorage) {
          print(
            '[ROLLBACK] Erro ao remover imagem '
                'publicada do Storage: '
                '$erroStorage',
          );
        }
      }

      // ========================================================
      // REMOVER PDF PUBLICADO
      // ========================================================

      if (pdfCopiado &&
          caminhoPdfPublicado != null &&
          caminhoPdfPublicado!
              .trim()
              .isNotEmpty) {
        try {
          await _storage
              .removerDocumentoPublicado(
            caminhoPdfPublicado!,
          );
        } catch (erroPdf) {
          print(
            '[ROLLBACK] Erro ao remover PDF '
                'publicado: $erroPdf',
          );
        }
      }

      print(
        '[ROLLBACK] Concluído. A obra pendente '
            'e suas imagens não devem ser eliminadas.',
      );

      print('================================================');

      rethrow;
    }
  }

  // ============================================================
  // TRANSFERIR SECÇÕES
  // ============================================================

  Future<void> _transferirSecoes(
      Obra obra,
      ) async {
    final conteudoTexto =
        obra.conteudoTexto;

    if (conteudoTexto == null ||
        conteudoTexto.trim().isEmpty) {
      print(
        '[DIAGNÓSTICO SECÇÕES] conteudo_texto '
            'vazio. Nenhuma secção para transferir.',
      );

      return;
    }

    try {
      final decoded =
      jsonDecode(conteudoTexto);

      if (decoded is! List) {
        print(
          '[DIAGNÓSTICO SECÇÕES] conteudo_texto '
              'não é uma lista.',
        );

        return;
      }

      if (decoded.isEmpty) {
        print(
          '[DIAGNÓSTICO SECÇÕES] Lista de '
              'secções vazia.',
        );

        return;
      }

      final registros =
      <Map<String, dynamic>>[];

      for (
      var i = 0;
      i < decoded.length;
      i++
      ) {
        final item =
        decoded[i];

        if (item is! Map) {
          continue;
        }

        final mapa =
        Map<String, dynamic>.from(
          item,
        );

        final titulo =
        (
            mapa['titulo'] ??
                mapa['titulo_secao'] ??
                'Secção ${i + 1}'
        ).toString();

        final conteudo =
        (
            mapa['conteudo'] ??
                ''
        ).toString();

        final ordem =
        mapa['ordem'] is int
            ? mapa['ordem']
            : int.tryParse(
          mapa['ordem']
              ?.toString() ??
              '',
        ) ??
            (i + 1);

        final nivel =
        mapa['nivel'] is int
            ? mapa['nivel']
            : int.tryParse(
          mapa['nivel']
              ?.toString() ??
              '',
        ) ??
            1;

        registros.add({
          'id':
          _uuid.v4(),
          'obra_id':
          obra.id,
          'titulo':
          titulo,
          'conteudo':
          conteudo,
          'ordem':
          ordem,
          'nivel':
          nivel,
        });
      }

      if (registros.isEmpty) {
        print(
          '[DIAGNÓSTICO SECÇÕES] Nenhum registro '
              'válido para inserir.',
        );

        return;
      }

      print(
        '[DIAGNÓSTICO SECÇÕES] A inserir '
            '${registros.length} secções...',
      );

      await _supabase
          .from('teste_secoes')
          .insert(
        registros,
      );

      print(
        '[DIAGNÓSTICO SECÇÕES] Secções '
            'transferidas com sucesso.',
      );
    } catch (e) {
      print(
        '[DIAGNÓSTICO SECÇÕES] Erro ao transferir '
            'secções: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // REJEITAR
  // ============================================================

  Future<void> rejeitar(
      String obraPendenteId,
      ) async {
    final idLimpo =
    obraPendenteId.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra pendente inválido.',
      );
    }

    final pendente =
    await carregarPorId(
      idLimpo,
    );

    await eliminarImagensPendentes(
      idLimpo,
    );

    if (pendente != null) {
      final caminhoPdf =
      pendente.urlDocumento.trim();

      if (caminhoPdf.isNotEmpty) {
        try {
          await _storage
              .removerDocumentoPendente(
            caminhoPdf,
          );
        } catch (e) {
          print(
            '[REJEITAR] Erro ao remover PDF '
                'pendente: $e',
          );
        }
      }
    }

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq(
      'id',
      idLimpo,
    );
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<void> excluir(
      String obraPendenteId,
      ) async {
    final idLimpo =
    obraPendenteId.trim();

    if (idLimpo.isEmpty) {
      return;
    }

    final pendente =
    await carregarPorId(
      idLimpo,
    );

    if (pendente == null) {
      return;
    }

    await eliminarImagensPendentes(
      idLimpo,
    );

    final caminhoPdf =
    pendente.urlDocumento.trim();

    if (caminhoPdf.isNotEmpty) {
      try {
        await _storage
            .removerDocumentoPendente(
          caminhoPdf,
        );
      } catch (e) {
        print(
          '[EXCLUIR] Erro ao remover PDF '
              'pendente: $e',
        );
      }
    }

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq(
      'id',
      idLimpo,
    );
  }

  // ============================================================
  // NOME DO ARQUIVO
  // ============================================================

  String _nomeArquivo(
      String caminho,
      ) {
    final partes =
    caminho.split('/');

    if (partes.isEmpty) {
      return caminho;
    }

    return partes.last;
  }
}
