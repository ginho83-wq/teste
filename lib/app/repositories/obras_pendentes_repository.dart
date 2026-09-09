import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra_pendente.dart';
import '../models/obra.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class ObrasPendentesRepository {
  ObrasPendentesRepository._();

  static final ObrasPendentesRepository instancia =
  ObrasPendentesRepository._();

  final SupabaseClient _supabase =
      SupabaseService.instancia.client;

  final StorageService _storage =
      StorageService.instancia;

  // ============================================================
  // CAMPOS
  // ============================================================

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
  // INSERIR OBRA PENDENTE
  // ============================================================

  Future<ObraPendente> inserir(
      ObraPendente obra,
      ) async {
    final dados = {
      'titulo': obra.titulo,
      'descricao': obra.descricao,
      'autor': obra.autor,
      'categoria': obra.categoria,
      'url_documento': obra.urlDocumento,
      'ano_obra': obra.anoObra,
      'user_id': obra.userId,
    };

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
  // LISTAR OBRAS PENDENTES
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
  // LISTAR OBRAS PENDENTES DO UTILIZADOR
  // ============================================================

  Future<List<ObraPendente>> carregarDoUsuario(
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
  // BUSCAR POR ID
  // ============================================================

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

  // ============================================================
  // APROVAR OBRA
  // ============================================================

  Future<Obra> aprovar(
      String id,
      ) async {
    // ----------------------------------------------------------
    // 1. BUSCAR OBRA PENDENTE
    // ----------------------------------------------------------

    final pendente = await carregarPorId(id);

    if (pendente == null) {
      throw Exception(
        'A obra pendente não foi encontrada.',
      );
    }

    if (pendente.id == null) {
      throw Exception(
        'A obra pendente não possui um ID válido.',
      );
    }

    // ----------------------------------------------------------
    // 2. DEFINIR CAMINHO DO DOCUMENTO PUBLICADO
    // ----------------------------------------------------------

    final caminhoPendente =
    pendente.urlDocumento.trim();

    if (caminhoPendente.isEmpty) {
      throw Exception(
        'A obra não possui documento associado.',
      );
    }

    final caminhoPublicado =
    _criarCaminhoPublicado(
      pendente,
    );

    // ----------------------------------------------------------
    // 3. BAIXAR PDF DO BUCKET PENDENTE
    // ----------------------------------------------------------

    final bytes = await _supabase.storage
        .from(StorageService.bucketPendentes)
        .download(caminhoPendente);

    // ----------------------------------------------------------
    // 4. ENVIAR PDF PARA BUCKET PUBLICADO
    // ----------------------------------------------------------

    await _supabase.storage
        .from(StorageService.bucketPublicadas)
        .uploadBinary(
      caminhoPublicado,
      bytes,
      fileOptions: const FileOptions(
        upsert: false,
        contentType: 'application/pdf',
      ),
    );

    // ----------------------------------------------------------
    // 5. OBTER URL PÚBLICA
    // ----------------------------------------------------------

    final urlPublica =
    _storage.obterUrlPublica(
      caminhoPublicado,
    );

    // ----------------------------------------------------------
    // 6. CRIAR OBRA PUBLICADA
    // ----------------------------------------------------------

    final dadosObra = {
      'id': pendente.id,
      'titulo': pendente.titulo,
      'descricao': pendente.descricao,
      'autor': pendente.autor,
      'categoria': pendente.categoria,
      'url_documento': urlPublica,
      'ano_obra': pendente.anoObra,
      'data_publicacao':
      pendente.dataPublicacao?.toIso8601String(),
      'user_id': pendente.userId,
    };

    try {
      final resposta = await _supabase
          .from('obras')
          .insert(dadosObra)
          .select()
          .single();

      // --------------------------------------------------------
      // 7. REMOVER PDF DO BUCKET PENDENTE
      // --------------------------------------------------------

      await _storage.removerDocumentoPendente(
        caminhoPendente,
      );

      // --------------------------------------------------------
      // 8. REMOVER REGISTRO PENDENTE
      // --------------------------------------------------------

      await _supabase
          .from('obras_pendentes')
          .delete()
          .eq('id', id);

      return Obra.fromMap(
        Map<String, dynamic>.from(resposta),
      );
    } catch (e) {
      // --------------------------------------------------------
      // LIMPEZA DO PDF PUBLICADO SE A OPERAÇÃO FALHAR
      // --------------------------------------------------------

      try {
        await _storage.removerDocumentoPublicado(
          caminhoPublicado,
        );
      } catch (_) {
        // Não substituir o erro original.
      }

      rethrow;
    }
  }

  // ============================================================
  // REJEITAR OBRA
  // ============================================================

  Future<void> rejeitar(
      String id,
      ) async {
    final pendente = await carregarPorId(id);

    if (pendente == null) {
      throw Exception(
        'A obra pendente não foi encontrada.',
      );
    }

    // ----------------------------------------------------------
    // REMOVER PDF
    // ----------------------------------------------------------

    final caminho = pendente.urlDocumento.trim();

    if (caminho.isNotEmpty) {
      try {
        await _storage.removerDocumentoPendente(
          caminho,
        );
      } catch (_) {
        // O registro poderá continuar sendo removido.
      }
    }

    // ----------------------------------------------------------
    // REMOVER REGISTRO
    // ----------------------------------------------------------

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq('id', id);
  }

  // ============================================================
  // EXCLUIR OBRA PENDENTE
  // ============================================================

  Future<void> excluir(
      String id,
      ) async {
    await rejeitar(id);
  }

  // ============================================================
  // CRIAR CAMINHO DO DOCUMENTO PUBLICADO
  // ============================================================

  String _criarCaminhoPublicado(
      ObraPendente obra,
      ) {
    final nomeArquivo =
        obra.urlDocumento.split('/').last;

    final userId = obra.userId;

    return '$userId/$nomeArquivo';
  }
}

