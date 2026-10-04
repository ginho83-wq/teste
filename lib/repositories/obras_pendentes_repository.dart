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

  final SupabaseClient _supabase = Supabase.instance.client;

  final StorageService _storage = StorageService.instancia;

  final ImagensStorageService _imagensStorage =
      ImagensStorageService.instancia;

  final ObrasImagensRepository _imagensRepository =
      ObrasImagensRepository.instancia;

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
  // CARREGAR POR ID
  // ============================================================

  Future<ObraPendente?> carregarPorId(
      String id,
      ) async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq(
      'id',
      id,
    )
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return ObraPendente.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  // ============================================================
  // CARREGAR DO UTILIZADOR
  // ============================================================

  Future<List<ObraPendente>> carregarDoUsuario(
      String userId,
      ) async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq(
      'user_id',
      userId,
    )
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
    final nomeArquivoLimpo = _nomeArquivo(nomeArquivo);
    final hashLimpo = hashPdf?.trim() ?? '';

    if (hashLimpo.isNotEmpty) {
      final respostaHash = await _supabase
          .from('obras_pendentes')
          .select('id, hash_pdf')
          .eq(
        'hash_pdf',
        hashLimpo,
      )
          .limit(1);

      if ((respostaHash as List).isNotEmpty) {
        return true;
      }
    }

    if (tituloLimpo.isNotEmpty && autorLimpo.isNotEmpty) {
      final respostaTituloAutor = await _supabase
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

      if ((respostaTituloAutor as List).isNotEmpty) {
        return true;
      }
    }

    if (nomeArquivoLimpo.isNotEmpty) {
      final respostaArquivo = await _supabase
          .from('obras_pendentes')
          .select('id, url_documento')
          .ilike(
        'url_documento',
        '%/$nomeArquivoLimpo',
      )
          .limit(20);

      if ((respostaArquivo as List).isNotEmpty) {
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

    if (hashPdf != null && hashPdf.trim().isNotEmpty) {
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
  // INSERIR IMAGEM PENDENTE
  //
  // IMPORTANTE:
  // Agora seguimos o mesmo padrão usado no INSERT do PDF:
  //
  // INSERT -> SELECT -> SINGLE
  //
  // Assim o Supabase confirma que a linha foi realmente criada.
  // ============================================================

  Future<Map<String, dynamic>> inserirImagemPendente({
    required String obraPendenteId,
    required String caminhoImagem,
    String? legenda,
    String posicao = 'depois_conteudo',
    int ordem = 1,
  }) async {
    final idLimpo = obraPendenteId.trim();
    final caminhoLimpo = caminhoImagem.trim();
    final posicaoLimpa = posicao.trim().isEmpty
        ? 'depois_conteudo'
        : posicao.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra pendente inválido.',
      );
    }

    if (caminhoLimpo.isEmpty) {
      throw Exception(
        'Caminho da imagem pendente inválido.',
      );
    }

    if (ordem < 1) {
      throw Exception(
        'A ordem da imagem deve ser maior que zero.',
      );
    }

    try {
      final resposta = await _supabase
          .from('obras_pendentes_imagens')
          .insert({
        'obra_pendente_id': idLimpo,
        'caminho_imagem': caminhoLimpo,
        'legenda': legenda,
        'posicao': posicaoLimpa,
        'ordem': ordem,
      })
          .select('''
            id,
            obra_pendente_id,
            caminho_imagem,
            legenda,
            posicao,
            ordem,
            created_at
          ''')
          .single();

      return Map<String, dynamic>.from(resposta);
    } on PostgrestException catch (e) {
      throw Exception(
        'Erro ao guardar a imagem na tabela '
            'obras_pendentes_imagens. '
            'Código: ${e.code}. '
            'Mensagem: ${e.message}. '
            'Detalhes: ${e.details}. '
            'Dica: ${e.hint ?? ''}',
      );
    }
  }

  // ============================================================
  // CARREGAR IMAGENS PENDENTES
  // ============================================================

  Future<List<Map<String, dynamic>>> carregarImagensPendentes(
      String obraPendenteId,
      ) async {
    if (obraPendenteId.trim().isEmpty) {
      return [];
    }

    final resposta = await _supabase
        .from('obras_pendentes_imagens')
        .select('''
          id,
          obra_pendente_id,
          caminho_imagem,
          legenda,
          posicao,
          ordem,
          created_at
        ''')
        .eq(
      'obra_pendente_id',
      obraPendenteId,
    )
        .order(
      'ordem',
      ascending: true,
    );

    return (resposta as List)
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // ============================================================
  // ELIMINAR IMAGENS PENDENTES
  // ============================================================

  Future<void> eliminarImagensPendentes(
      String obraPendenteId,
      ) async {
    if (obraPendenteId.trim().isEmpty) {
      return;
    }

    final imagens = await carregarImagensPendentes(
      obraPendenteId,
    );

    // Primeiro remover os ficheiros do Storage.
    for (final imagem in imagens) {
      final caminho =
          imagem['caminho_imagem']?.toString() ?? '';

      if (caminho.isEmpty) {
        continue;
      }

      try {
        await _imagensStorage.removerImagemPendente(
          caminho,
        );
      } catch (_) {}
    }

    // Depois remover os registos da tabela.
    await _supabase
        .from('obras_pendentes_imagens')
        .delete()
        .eq(
      'obra_pendente_id',
      obraPendenteId,
    );
  }

  // ============================================================
  // APROVAR OBRA
  // ============================================================

  Future<Obra> aprovar(
      String id,
      ) async {
    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra pendente inválido.',
      );
    }

    // ----------------------------------------------------------
    // 1. CARREGAR OBRA PENDENTE
    // ----------------------------------------------------------

    final pendente = await carregarPorId(idLimpo);

    if (pendente == null) {
      throw Exception(
        'Obra pendente não encontrada.',
      );
    }

    if (pendente.urlDocumento.trim().isEmpty) {
      throw Exception(
        'O caminho do arquivo da obra pendente '
            'não foi encontrado.',
      );
    }

    // ----------------------------------------------------------
    // 2. HASH
    // ----------------------------------------------------------

    final respostaHash = await _supabase
        .from('obras_pendentes')
        .select('hash_pdf')
        .eq(
      'id',
      idLimpo,
    )
        .maybeSingle();

    final hashPdf =
    respostaHash?['hash_pdf']?.toString();

    // ----------------------------------------------------------
    // 3. CARREGAR IMAGENS PENDENTES
    // ----------------------------------------------------------

    final imagensPendentes =
    await carregarImagensPendentes(idLimpo);

    // ----------------------------------------------------------
    // 4. COPIAR PDF PARA O BUCKET PUBLICADO
    // ----------------------------------------------------------

    final caminhoPdfPendente =
        pendente.urlDocumento;

    final caminhoPdfPublicado =
    await _storage.copiarDocumentoParaPublicadas(
      caminhoPendente: caminhoPdfPendente,
      userId: pendente.userId,
      nomeArquivo: _nomeArquivo(
        caminhoPdfPendente,
      ),
    );

    final urlPdfPublica =
    _storage.obterUrlPublica(
      caminhoPdfPublicado,
    );

    // ----------------------------------------------------------
    // 5. CRIAR OBRA PUBLICADA
    // ----------------------------------------------------------

    final dadosObra = <String, dynamic>{
      'titulo': pendente.titulo,
      'descricao': pendente.descricao,
      'conteudo_texto': pendente.conteudoTexto,
      'autor': pendente.autor,
      'categoria': pendente.categoria,
      'url_documento': urlPdfPublica,
      'ano_obra': pendente.anoObra,
      'data_publicacao':
      pendente.dataPublicacao.toIso8601String(),
      'numero_paginas': pendente.numeroPaginas,
      'user_id': pendente.userId,
      'tamanho_arquivo_bytes':
      pendente.tamanhoArquivoBytes,
      'hash_pdf': hashPdf,
    };

    final resposta = await _supabase
        .from('obras')
        .insert(dadosObra)
        .select('''
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
        ''')
        .single();

    final obraPublicada = Obra.fromMap(
      Map<String, dynamic>.from(resposta),
    );

    final imagensPublicadas = <String>[];

    try {
      // --------------------------------------------------------
      // 6. TRANSFERIR SECÇÕES
      // --------------------------------------------------------

      await _transferirSecoes(
        obraId: obraPublicada.id,
        conteudoTexto: pendente.conteudoTexto,
      );

      // --------------------------------------------------------
      // 7. TRANSFERIR IMAGENS
      // --------------------------------------------------------

      for (final imagem in imagensPendentes) {
        final caminhoPendente =
            imagem['caminho_imagem']?.toString() ?? '';

        if (caminhoPendente.isEmpty) {
          continue;
        }

        final caminhoPublicado =
        await _imagensStorage.copiarImagemParaPublicada(
          caminhoPendente: caminhoPendente,
          obraId: obraPublicada.id,
          nomeArquivo: _nomeArquivo(
            caminhoPendente,
          ),
        );

        imagensPublicadas.add(
          caminhoPublicado,
        );

        final urlImagem =
        _imagensStorage.obterUrlPublica(
          caminhoPublicado,
        );

        final legenda =
        imagem['legenda']?.toString();

        final posicao =
            imagem['posicao']?.toString() ??
                'depois_conteudo';

        final ordem = int.tryParse(
          imagem['ordem']?.toString() ?? '',
        ) ??
            1;

        await _imagensRepository.inserir(
          ObraImagem(
            obraId: obraPublicada.id,
            urlImagem: urlImagem,
            legenda: legenda,
            posicao: posicao,
            ordem: ordem,
          ),
        );
      }
    } catch (e) {
      // ========================================================
      // LIMPEZA COMPLETA EM CASO DE FALHA
      // ========================================================

      // A. Remover registos das imagens publicadas.
      try {
        await _imagensRepository.eliminarPorObra(
          obraPublicada.id,
        );
      } catch (_) {}

      // B. Remover ficheiros das imagens publicadas.
      for (final caminho in imagensPublicadas) {
        try {
          await _imagensStorage.removerImagem(
            caminho,
          );
        } catch (_) {}
      }

      // C. Remover secções.
      try {
        await _supabase
            .from('teste_secoes')
            .delete()
            .eq(
          'obra_id',
          obraPublicada.id,
        );
      } catch (_) {}

      // D. Remover obra publicada.
      try {
        await _supabase
            .from('obras')
            .delete()
            .eq(
          'id',
          obraPublicada.id,
        );
      } catch (_) {}

      // E. Remover PDF publicado.
      try {
        await _storage.removerDocumentoPublicado(
          caminhoPdfPublicado,
        );
      } catch (_) {}

      rethrow;
    }

    // ==========================================================
    // 8. LIMPAR DADOS PENDENTES
    // ==========================================================

    await eliminarImagensPendentes(
      idLimpo,
    );

    // ----------------------------------------------------------
    // 9. REMOVER REGISTO DA OBRA PENDENTE
    // ----------------------------------------------------------

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq(
      'id',
      idLimpo,
    );

    // ----------------------------------------------------------
    // 10. REMOVER PDF PENDENTE
    // ----------------------------------------------------------

    try {
      await _storage.removerDocumentoPendente(
        caminhoPdfPendente,
      );
    } catch (_) {}

    return obraPublicada;
  }

  // ============================================================
  // TRANSFERIR SECÇÕES
  // ============================================================

  Future<void> _transferirSecoes({
    required String obraId,
    required String? conteudoTexto,
  }) async {
    if (conteudoTexto == null ||
        conteudoTexto.trim().isEmpty) {
      return;
    }

    dynamic dados;

    try {
      dados = jsonDecode(
        conteudoTexto.trim(),
      );
    } catch (_) {
      throw Exception(
        'Não foi possível interpretar as secções da obra. '
            'O conteúdo das secções não está num formato JSON válido.',
      );
    }

    if (dados is! List) {
      throw Exception(
        'O conteúdo das secções da obra possui um formato inválido.',
      );
    }

    if (dados.isEmpty) {
      return;
    }

    final secoes = <Map<String, dynamic>>[];

    for (var i = 0; i < dados.length; i++) {
      final item = dados[i];

      if (item is! Map) {
        continue;
      }

      final mapa = Map<String, dynamic>.from(
        item,
      );

      final titulo =
          mapa['titulo']?.toString().trim() ?? '';

      final conteudo =
          mapa['conteudo']?.toString().trim() ?? '';

      if (titulo.isEmpty && conteudo.isEmpty) {
        continue;
      }

      final ordem = int.tryParse(
        mapa['ordem']?.toString() ?? '',
      ) ??
          (secoes.length + 1);

      final nivel = int.tryParse(
        mapa['nivel']?.toString() ?? '',
      ) ??
          1;

      secoes.add({
        'id': _gerarIdSecao(),
        'obra_id': obraId,
        'titulo': titulo,
        'conteudo': conteudo,
        'ordem': ordem,
        'nivel': nivel,
      });
    }

    if (secoes.isEmpty) {
      return;
    }

    secoes.sort(
          (a, b) => (a['ordem'] as int).compareTo(
        b['ordem'] as int,
      ),
    );

    await _supabase
        .from('teste_secoes')
        .insert(secoes);
  }

  // ============================================================
  // GERAR ID DA SECÇÃO
  // ============================================================

  String _gerarIdSecao() {
    return const Uuid().v4();
  }

  // ============================================================
  // REJEITAR
  // ============================================================

  Future<void> rejeitar(
      String id,
      ) async {
    final idLimpo = id.trim();

    if (idLimpo.isEmpty) {
      throw Exception(
        'ID da obra pendente inválido.',
      );
    }

    final pendente = await carregarPorId(
      idLimpo,
    );

    if (pendente == null) {
      throw Exception(
        'Obra pendente não encontrada.',
      );
    }

    // Primeiro eliminar imagens pendentes.
    await eliminarImagensPendentes(
      idLimpo,
    );

    // Depois eliminar o PDF pendente.
    if (pendente.urlDocumento.trim().isNotEmpty) {
      try {
        await _storage.removerDocumentoPendente(
          pendente.urlDocumento,
        );
      } catch (_) {}
    }

    // Por último eliminar a obra pendente.
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
      String id,
      ) async {
    await rejeitar(id);
  }

  // ============================================================
  // NOME DO ARQUIVO
  // ============================================================

  String _nomeArquivo(
      String caminho,
      ) {
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
