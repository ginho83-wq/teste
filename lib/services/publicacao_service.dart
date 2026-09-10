import 'dart:typed_data';

import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class PublicacaoService {
  PublicacaoService._();

  static final PublicacaoService instancia = PublicacaoService._();

  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

  final StorageService _storage = StorageService.instancia;

  final AuthService _auth = AuthService.instancia;

  Future<ObraPendente> publicar({
    required String titulo,
    String? descricao,
    required String autor,
    required String categoria,
    required Uint8List arquivoPdf,
    required String nomeArquivo,
    int? anoObra,
  }) async {
    final usuario = _auth.usuarioAtual;

    if (usuario == null) {
      throw Exception('É necessário estar autenticado para publicar.');
    }

    final tituloLimpo = titulo.trim();
    final autorLimpo = autor.trim();
    final categoriaLimpa = categoria.trim();
    final nomeArquivoLimpo = nomeArquivo.trim();

    if (tituloLimpo.isEmpty) {
      throw Exception('Informe o título da obra.');
    }

    if (autorLimpo.isEmpty) {
      throw Exception('Informe o autor da obra.');
    }

    if (categoriaLimpa.isEmpty) {
      throw Exception('Selecione a categoria da obra.');
    }

    if (arquivoPdf.isEmpty) {
      throw Exception('O arquivo PDF está vazio.');
    }

    if (!nomeArquivoLimpo.toLowerCase().endsWith('.pdf')) {
      throw Exception('O arquivo selecionado deve estar no formato PDF.');
    }

    String? caminhoPendente;

    try {
      caminhoPendente = await _storage.enviarDocumentoPendente(
        userId: usuario.id,
        nomeArquivo: nomeArquivoLimpo,
        bytes: arquivoPdf,
      );

      final obra = ObraPendente(
        titulo: tituloLimpo,
        descricao: descricao?.trim().isEmpty == true
            ? null
            : descricao?.trim(),
        autor: autorLimpo,
        categoria: categoriaLimpa,
        urlDocumento: caminhoPendente,
        anoObra: anoObra,
        userId: usuario.id,
      );

      return await _repository.inserir(obra);
    } catch (e) {
      if (caminhoPendente != null) {
        try {
          await _storage.removerDocumentoPendente(caminhoPendente);
        } catch (_) {}
      }

      rethrow;
    }
  }
}
