import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class StorageService {
  StorageService._();

  static final StorageService instancia = StorageService._();

  final SupabaseClient _supabase =
      SupabaseService.instancia.client;

  static const String bucketPendentes = 'obras_pendentes';
  static const String bucketPublicadas = 'obras';

  // ============================================================
  // UPLOAD DE DOCUMENTO PENDENTE
  // ============================================================

  Future<String> enviarDocumentoPendente({
    required Uint8List bytes,
    required String nomeArquivo,
    required String userId,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('O arquivo está vazio.');
    }

    if (userId.trim().isEmpty) {
      throw Exception('Utilizador não identificado.');
    }

    final nomeSeguro = _normalizarNomeArquivo(nomeArquivo);

    final caminho =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$nomeSeguro';

    await _supabase.storage
        .from(bucketPendentes)
        .uploadBinary(
      caminho,
      bytes,
      fileOptions: const FileOptions(
        upsert: false,
        contentType: 'application/pdf',
      ),
    );

    return caminho;
  }

  // ============================================================
  // OBTER URL DO DOCUMENTO PÚBLICO
  // ============================================================

  String obterUrlPublica(String caminho) {
    return _supabase.storage
        .from(bucketPublicadas)
        .getPublicUrl(caminho);
  }

  // ============================================================
  // OBTER URL ASSINADA DO DOCUMENTO PENDENTE
  // ============================================================

  Future<String> obterUrlPendente(
      String caminho, {
        int validadeSegundos = 3600,
      }) async {
    return await _supabase.storage
        .from(bucketPendentes)
        .createSignedUrl(
      caminho,
      validadeSegundos,
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
        .from(bucketPendentes)
        .remove([caminho]);
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
        .from(bucketPublicadas)
        .remove([caminho]);
  }

  // ============================================================
  // COPIAR DOCUMENTO PARA BUCKET PUBLICADO
  // ============================================================

  Future<void> copiarParaPublicadas({
    required String caminhoOrigem,
    required String caminhoDestino,
  }) async {
    await _supabase.storage
        .from(bucketPendentes)
        .copy(
      caminhoOrigem,
      caminhoDestino,
    );
  }

  // ============================================================
  // MOVER DOCUMENTO PARA BUCKET PUBLICADO
  // ============================================================

  Future<void> moverParaPublicadas({
    required String caminhoOrigem,
    required String caminhoDestino,
  }) async {
    await _supabase.storage
        .from(bucketPendentes)
        .move(
      caminhoOrigem,
      caminhoDestino,
    );
  }

  // ============================================================
  // VERIFICAR SE O DOCUMENTO EXISTE
  // ============================================================

  Future<bool> documentoPendenteExiste(
      String caminho,
      ) async {
    if (caminho.trim().isEmpty) {
      return false;
    }

    final partes = caminho.split('/');

    if (partes.length < 2) {
      return false;
    }

    final pasta = partes.sublist(0, partes.length - 1).join('/');
    final nomeArquivo = partes.last;

    final arquivos = await _supabase.storage
        .from(bucketPendentes)
        .list(path: pasta);

    return arquivos.any(
          (arquivo) => arquivo.name == nomeArquivo,
    );
  }

  // ============================================================
  // NORMALIZAR NOME DO ARQUIVO
  // ============================================================

  String _normalizarNomeArquivo(String nome) {
    var resultado = nome.trim();

    resultado = resultado.replaceAll(
      RegExp(r'[^\w\-.]'),
      '_',
    );

    if (resultado.isEmpty) {
      resultado = 'documento.pdf';
    }

    return resultado;
  }
}

