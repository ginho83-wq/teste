import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ImagensStorageService {
  ImagensStorageService._();

  static final ImagensStorageService instancia =
  ImagensStorageService._();

  final SupabaseClient _supabase =
      SupabaseService.instancia.client;

  // ============================================================
  // BUCKET ÚNICO DAS IMAGENS
  // ============================================================

  /// Todas as imagens, pendentes e publicadas,
  /// ficam neste único bucket.
  static const String bucketImagens =
      'imagens-obras';

  // ============================================================
  // ENVIAR IMAGEM PUBLICADA
  // ============================================================

  Future<String> enviarImagem({
    required String obraId,
    required String nomeArquivo,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (obraId.trim().isEmpty) {
      throw Exception(
        'ID da obra inválido.',
      );
    }

    if (bytes.isEmpty) {
      throw Exception(
        'A imagem está vazia.',
      );
    }

    final nomeSeguro =
    _normalizarNomeArquivo(nomeArquivo);

    final caminho =
        '$obraId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    await _supabase.storage
        .from(bucketImagens)
        .uploadBinary(
      caminho,
      bytes,
      fileOptions: FileOptions(
        contentType:
        contentType ??
            _obterContentType(
              nomeSeguro,
            ),
        upsert: false,
      ),
    );

    return caminho;
  }

  // ============================================================
  // ENVIAR IMAGEM PENDENTE
  // ============================================================

  Future<String> enviarImagemPendente({
    required String obraPendenteId,
    required String nomeArquivo,
    required Uint8List bytes,
    String? contentType,
  }) async {
    if (obraPendenteId.trim().isEmpty) {
      throw Exception(
        'ID da obra pendente inválido.',
      );
    }

    if (bytes.isEmpty) {
      throw Exception(
        'A imagem está vazia.',
      );
    }

    final nomeSeguro =
    _normalizarNomeArquivo(nomeArquivo);

    final caminho =
        '$obraPendenteId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    // IMPORTANTE:
    // As imagens pendentes usam o mesmo bucket
    // "imagens-obras".
    await _supabase.storage
        .from(bucketImagens)
        .uploadBinary(
      caminho,
      bytes,
      fileOptions: FileOptions(
        contentType:
        contentType ??
            _obterContentType(
              nomeSeguro,
            ),
        upsert: false,
      ),
    );

    return caminho;
  }

  // ============================================================
  // OBTER URL PÚBLICA DA IMAGEM
  // ============================================================

  String obterUrlPublica(
      String caminho,
      ) {
    if (caminho.trim().isEmpty) {
      throw Exception(
        'Caminho da imagem inválido.',
      );
    }

    return _supabase.storage
        .from(bucketImagens)
        .getPublicUrl(caminho);
  }

  // ============================================================
  // REMOVER IMAGEM PUBLICADA
  // ============================================================

  Future<void> removerImagem(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return;
    }

    await _supabase.storage
        .from(bucketImagens)
        .remove([
      caminho,
    ]);
  }

  // ============================================================
  // REMOVER IMAGEM PENDENTE
  // ============================================================

  Future<void> removerImagemPendente(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return;
    }

    // Imagens pendentes também estão em "imagens-obras".
    await _supabase.storage
        .from(bucketImagens)
        .remove([
      caminho,
    ]);
  }

  // ============================================================
  // BAIXAR IMAGEM PUBLICADA
  // ============================================================

  Future<Uint8List> baixarImagem(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      throw Exception(
        'Caminho da imagem inválido.',
      );
    }

    return await _supabase.storage
        .from(bucketImagens)
        .download(caminho);
  }

  // ============================================================
  // BAIXAR IMAGEM PENDENTE
  // ============================================================

  Future<Uint8List> baixarImagemPendente(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      throw Exception(
        'Caminho da imagem pendente inválido.',
      );
    }

    // As imagens pendentes estão no mesmo bucket.
    return await _supabase.storage
        .from(bucketImagens)
        .download(caminho);
  }

  // ============================================================
  // COPIAR IMAGEM PENDENTE → PUBLICADA
  // ============================================================

  Future<String> copiarImagemParaPublicada({
    required String caminhoPendente,
    required String obraId,
    required String nomeArquivo,
  }) async {
    final bytes =
    await baixarImagemPendente(
      caminhoPendente,
    );

    return await enviarImagem(
      obraId: obraId,
      nomeArquivo: nomeArquivo,
      bytes: bytes,
    );
  }

  // ============================================================
  // NORMALIZAR NOME DO FICHEIRO
  // ============================================================

  String _normalizarNomeArquivo(
      String nome,
      ) {
    var resultado = nome.trim();

    if (resultado.isEmpty) {
      resultado = 'imagem';
    }

    resultado = resultado.replaceAll(
      RegExp(r'[^\w\-.]'),
      '_',
    );

    resultado = resultado.replaceAll(
      RegExp(r'_+'),
      '_',
    );

    return resultado;
  }

  // ============================================================
  // CONTENT TYPE
  // ============================================================

  String _obterContentType(
      String nomeArquivo,
      ) {
    final nome =
    nomeArquivo.toLowerCase();

    if (nome.endsWith('.png')) {
      return 'image/png';
    }

    if (nome.endsWith('.webp')) {
      return 'image/webp';
    }

    if (nome.endsWith('.gif')) {
      return 'image/gif';
    }

    if (nome.endsWith('.svg')) {
      return 'image/svg+xml';
    }

    if (nome.endsWith('.jpg') ||
        nome.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    return 'image/jpeg';
  }
}
