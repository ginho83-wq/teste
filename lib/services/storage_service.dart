import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class StorageService {
  StorageService._();

  static final StorageService instancia = StorageService._();

  final SupabaseClient _supabase = SupabaseService.instancia.client;

  static const String bucketObrasPendentes = 'obras_pendentes';
  static const String bucketObras = 'obras';

  // ============================================================
  // ENVIAR DOCUMENTO PARA OBRAS PENDENTES
  // ============================================================

  Future<String> enviarDocumentoPendente({
    required String userId,
    required String nomeArquivo,
    required Uint8List bytes,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('Utilizador inválido.');
    }

    if (bytes.isEmpty) {
      throw Exception('O arquivo está vazio.');
    }

    final nomeSeguro = _normalizarNomeArquivo(nomeArquivo);

    final caminho =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    await _supabase.storage.from(bucketObrasPendentes).uploadBinary(
      caminho,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      ),
    );

    return caminho;
  }

  // ============================================================
  // BAIXAR DOCUMENTO PENDENTE
  // ============================================================

  Future<Uint8List> baixarDocumentoPendente(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      throw Exception('Caminho do documento inválido.');
    }

    final bytes = await _supabase.storage
        .from(bucketObrasPendentes)
        .download(caminho);

    if (bytes.isEmpty) {
      throw Exception('O documento pendente está vazio.');
    }

    return bytes;
  }

  // ============================================================
  // OBTER URL ASSINADA DO DOCUMENTO PENDENTE
  // ============================================================

  Future<String> obterUrlPendente(
      String caminho, {
        int duracaoSegundos = 3600,
      }) async {
    if (caminho.trim().isEmpty) {
      throw Exception('Caminho do documento inválido.');
    }

    return await _supabase.storage
        .from(bucketObrasPendentes)
        .createSignedUrl(
      caminho,
      duracaoSegundos,
    );
  }

  // ============================================================
  // VERIFICAR SE DOCUMENTO PENDENTE EXISTE
  // ============================================================

  Future<bool> documentoPendenteExiste(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return false;
    }

    try {
      final pasta = _obterPasta(caminho);
      final nome = _obterNomeArquivo(caminho);

      final arquivos = await _supabase.storage
          .from(bucketObrasPendentes)
          .list(path: pasta);

      return arquivos.any(
            (arquivo) => arquivo.name == nome,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REMOVER DOCUMENTO PENDENTE
  // ============================================================

  Future<void> removerDocumentoPendente(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return;
    }

    await _supabase.storage
        .from(bucketObrasPendentes)
        .remove([caminho]);
  }

  // ============================================================
  // ENVIAR DOCUMENTO PUBLICADO
  // ============================================================

  Future<String> enviarDocumentoPublicado({
    required String userId,
    required String nomeArquivo,
    required Uint8List bytes,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('Utilizador inválido.');
    }

    if (bytes.isEmpty) {
      throw Exception('O arquivo está vazio.');
    }

    final nomeSeguro = _normalizarNomeArquivo(nomeArquivo);

    final caminho =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    await _supabase.storage.from(bucketObras).uploadBinary(
      caminho,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: false,
      ),
    );

    return caminho;
  }

  // ============================================================
  // OBTER URL PÚBLICA
  // ============================================================

  String obterUrlPublica(
      String caminho,
      ) {
    if (caminho.trim().isEmpty) {
      throw Exception('Caminho do documento inválido.');
    }

    return _supabase.storage
        .from(bucketObras)
        .getPublicUrl(caminho);
  }

  // ============================================================
  // REMOVER DOCUMENTO PUBLICADO
  // ============================================================

  Future<void> removerDocumentoPublicado(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return;
    }

    await _supabase.storage
        .from(bucketObras)
        .remove([caminho]);
  }

  // ============================================================
  // COPIAR DOCUMENTO PENDENTE PARA PUBLICADAS
  // ============================================================

  Future<String> copiarParaPublicadas({
    required String caminhoPendente,
    required String userId,
    required String nomeArquivo,
  }) async {
    final bytes = await baixarDocumentoPendente(
      caminhoPendente,
    );

    return await enviarDocumentoPublicado(
      userId: userId,
      nomeArquivo: nomeArquivo,
      bytes: bytes,
    );
  }

  // ============================================================
  // MOVER DOCUMENTO PARA PUBLICADAS
  // ============================================================

  Future<String> moverParaPublicadas({
    required String caminhoPendente,
    required String userId,
    required String nomeArquivo,
  }) async {
    final caminhoPublicado = await copiarParaPublicadas(
      caminhoPendente: caminhoPendente,
      userId: userId,
      nomeArquivo: nomeArquivo,
    );

    try {
      await removerDocumentoPendente(
        caminhoPendente,
      );
    } catch (_) {
      // O documento publicado já existe.
    }

    return caminhoPublicado;
  }

  // ============================================================
  // NORMALIZAR NOME DO ARQUIVO
  // ============================================================

  String _normalizarNomeArquivo(
      String nome,
      ) {
    var resultado = nome.trim();

    if (resultado.isEmpty) {
      resultado = 'documento.pdf';
    }

    resultado = resultado.replaceAll(
      RegExp(r'[^\w\-.]'),
      '_',
    );

    resultado = resultado.replaceAll(
      RegExp(r'_+'),
      '_',
    );

    if (!resultado.toLowerCase().endsWith('.pdf')) {
      resultado = '$resultado.pdf';
    }

    return resultado;
  }

  // ============================================================
  // OBTER PASTA DO CAMINHO
  // ============================================================

  String _obterPasta(
      String caminho,
      ) {
    final indice = caminho.lastIndexOf('/');

    if (indice == -1) {
      return '';
    }

    return caminho.substring(0, indice);
  }

  // ============================================================
  // OBTER NOME DO ARQUIVO
  // ============================================================

  String _obterNomeArquivo(
      String caminho,
      ) {
    final indice = caminho.lastIndexOf('/');

    if (indice == -1) {
      return caminho;
    }

    return caminho.substring(indice + 1);
  }
}
