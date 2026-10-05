import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class StorageService {
  StorageService._();

  static final StorageService instancia =
  StorageService._();

  final SupabaseClient _supabase =
      SupabaseService.instancia.client;

  // ============================================================
  // BUCKETS
  // ============================================================

  /// Bucket dos documentos PDF que aguardam aprovação.
  static const String bucketObrasPendentes =
      'obras_pendentes';

  /// Bucket dos documentos PDF publicados.
  static const String bucketObras = 'obras';

  // ============================================================
  // DOCUMENTO PDF — PENDENTE
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

    final nomeSeguro =
    _normalizarNomeArquivo(nomeArquivo);

    final caminho =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    await _supabase.storage
        .from(bucketObrasPendentes)
        .uploadBinary(
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
      throw Exception(
        'Caminho do documento inválido.',
      );
    }

    final bytes = await _supabase.storage
        .from(bucketObrasPendentes)
        .download(caminho);

    if (bytes.isEmpty) {
      throw Exception(
        'O documento pendente está vazio.',
      );
    }

    return bytes;
  }

  // ============================================================
  // URL ASSINADA — DOCUMENTO PENDENTE
  // ============================================================

  Future<String> obterUrlPendente(
      String caminho, {
        int duracaoSegundos = 3600,
      }) async {
    if (caminho.trim().isEmpty) {
      throw Exception(
        'Caminho do documento inválido.',
      );
    }

    return await _supabase.storage
        .from(bucketObrasPendentes)
        .createSignedUrl(
      caminho,
      duracaoSegundos,
    );
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
        .remove([
      caminho,
    ]);
  }

  // ============================================================
  // DOCUMENTO PDF — PUBLICADO
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

    final nomeSeguro =
    _normalizarNomeArquivo(nomeArquivo);

    final caminho =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    await _supabase.storage
        .from(bucketObras)
        .uploadBinary(
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
  // URL PÚBLICA — DOCUMENTO PUBLICADO
  // ============================================================

  String obterUrlPublica(
      String caminho,
      ) {
    if (caminho.trim().isEmpty) {
      throw Exception(
        'Caminho do documento inválido.',
      );
    }

    return _supabase.storage
        .from(bucketObras)
        .getPublicUrl(caminho);
  }

  // ============================================================
  // COPIAR PDF PENDENTE → PUBLICADO
  // ============================================================

  Future<String> copiarDocumentoParaPublicadas({
    required String caminhoPendente,
    required String userId,
    required String nomeArquivo,
  }) async {
    if (caminhoPendente.trim().isEmpty) {
      throw Exception(
        'Caminho do PDF pendente inválido.',
      );
    }

    final bytes =
    await baixarDocumentoPendente(
      caminhoPendente,
    );

    return await enviarDocumentoPublicado(
      userId: userId,
      nomeArquivo: nomeArquivo,
      bytes: bytes,
    );
  }

  // ============================================================
  // REMOVER PDF PUBLICADO
  // ============================================================

  Future<void> removerDocumentoPublicado(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return;
    }

    await _supabase.storage
        .from(bucketObras)
        .remove([
      caminho,
    ]);
  }

  // ============================================================
  // NORMALIZAR NOME DO PDF
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

    if (!resultado
        .toLowerCase()
        .endsWith('.pdf')) {
      resultado = '$resultado.pdf';
    }

    return resultado;
  }
}
