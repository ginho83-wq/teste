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

  static const String bucketObrasPendentes =
      'obras_pendentes';

  static const String bucketObras =
      'obras';

  static const String bucketCapasPendentes =
      'capas-pendentes';

  static const String bucketCapasObras =
      'capas-obras';

  // ============================================================
  // DOCUMENTO PDF — PENDENTES
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
        .remove([caminho]);
  }

  // ============================================================
  // DOCUMENTO PUBLICADO
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
  // URL PÚBLICA DO PDF
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
  // COPIAR PDF PARA PUBLICADAS
  // ============================================================

  Future<String> copiarDocumentoParaPublicadas({
    required String caminhoPendente,
    required String userId,
    required String nomeArquivo,
  }) async {
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
        .remove([caminho]);
  }

  // ============================================================
  // CAPA — PENDENTES
  // ============================================================

  Future<String> enviarCapaPendente({
    required String userId,
    required String nomeArquivo,
    required Uint8List bytes,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('Utilizador inválido.');
    }

    if (bytes.isEmpty) {
      throw Exception(
        'A imagem da capa está vazia.',
      );
    }

    final nomeBase =
    _nomeBaseSemExtensao(nomeArquivo);

    final nomeCapa =
        '${nomeBase}_capa.png';

    final caminho =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$nomeCapa';

    await _supabase.storage
        .from(bucketCapasPendentes)
        .uploadBinary(
      caminho,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/png',
        upsert: false,
      ),
    );

    return caminho;
  }

  // ============================================================
  // BAIXAR CAPA PENDENTE
  // ============================================================

  Future<Uint8List> baixarCapaPendente(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      throw Exception(
        'Caminho da capa inválido.',
      );
    }

    final bytes = await _supabase.storage
        .from(bucketCapasPendentes)
        .download(caminho);

    if (bytes.isEmpty) {
      throw Exception(
        'A capa pendente está vazia.',
      );
    }

    return bytes;
  }

  // ============================================================
  // REMOVER CAPA PENDENTE
  // ============================================================

  Future<void> removerCapaPendente(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return;
    }

    await _supabase.storage
        .from(bucketCapasPendentes)
        .remove([caminho]);
  }

  // ============================================================
  // ENVIAR CAPA PUBLICADA
  // ============================================================

  Future<String> enviarCapaPublicada({
    required String userId,
    required String nomeArquivo,
    required Uint8List bytes,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('Utilizador inválido.');
    }

    if (bytes.isEmpty) {
      throw Exception(
        'A imagem da capa está vazia.',
      );
    }

    final nomeSeguro =
    _normalizarNomeCapa(nomeArquivo);

    final caminho =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    await _supabase.storage
        .from(bucketCapasObras)
        .uploadBinary(
      caminho,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/png',
        upsert: false,
      ),
    );

    return caminho;
  }

  // ============================================================
  // URL PÚBLICA DA CAPA
  // ============================================================

  String obterUrlCapaPublica(
      String caminho,
      ) {
    if (caminho.trim().isEmpty) {
      throw Exception(
        'Caminho da capa inválido.',
      );
    }

    return _supabase.storage
        .from(bucketCapasObras)
        .getPublicUrl(caminho);
  }

  // ============================================================
  // COPIAR CAPA PARA PUBLICADAS
  // ============================================================

  Future<String> copiarCapaParaPublicadas({
    required String caminhoPendente,
    required String userId,
    required String nomeArquivo,
  }) async {
    final bytes =
    await baixarCapaPendente(
      caminhoPendente,
    );

    return await enviarCapaPublicada(
      userId: userId,
      nomeArquivo: nomeArquivo,
      bytes: bytes,
    );
  }

  // ============================================================
  // REMOVER CAPA PUBLICADA
  // ============================================================

  Future<void> removerCapaPublicada(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return;
    }

    await _supabase.storage
        .from(bucketCapasObras)
        .remove([caminho]);
  }

  // ============================================================
  // NORMALIZAÇÃO DE ARQUIVOS
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

  String _nomeBaseSemExtensao(
      String nome,
      ) {
    var resultado = nome.trim();

    final indice =
    resultado.lastIndexOf('.');

    if (indice > 0) {
      resultado =
          resultado.substring(0, indice);
    }

    resultado = resultado.replaceAll(
      RegExp(r'[^\w\-.]'),
      '_',
    );

    resultado = resultado.replaceAll(
      RegExp(r'_+'),
      '_',
    );

    if (resultado.isEmpty) {
      resultado = 'documento';
    }

    return resultado;
  }

  String _normalizarNomeCapa(
      String nome,
      ) {
    return '${_nomeBaseSemExtensao(nome)}_capa.png';
  }
}
