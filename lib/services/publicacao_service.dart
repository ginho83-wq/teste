import 'dart:typed_data';

import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class PublicacaoService {
  PublicacaoService._();

  static final PublicacaoService instancia =
  PublicacaoService._();

  final ObrasPendentesRepository _repository =
      ObrasPendentesRepository.instancia;

  final StorageService _storage =
      StorageService.instancia;

  final AuthService _auth =
      AuthService.instancia;

  // ============================================================
  // PUBLICAR OBRA
  // ============================================================

  Future<ObraPendente> publicar({
    required String titulo,
    String? descricao,
    required String autor,
    required String categoria,
    required Uint8List arquivoPdf,
    required String nomeArquivo,
    int? anoObra,
  }) async {
    // ----------------------------------------------------------
    // VALIDAR UTILIZADOR
    // ----------------------------------------------------------

    final usuario = _auth.usuarioAtual;

    if (usuario == null) {
      throw Exception(
        'É necessário iniciar sessão para publicar uma obra.',
      );
    }

    final userId = usuario.id;

    // ----------------------------------------------------------
    // NORMALIZAR DADOS
    // ----------------------------------------------------------

    final tituloFinal = titulo.trim();
    final descricaoFinal = descricao?.trim();
    final autorFinal = autor.trim();
    final categoriaFinal = categoria.trim();
    final nomeArquivoFinal = nomeArquivo.trim();

    // ----------------------------------------------------------
    // VALIDAÇÕES
    // ----------------------------------------------------------

    if (tituloFinal.isEmpty) {
      throw Exception('O título da obra é obrigatório.');
    }

    if (autorFinal.isEmpty) {
      throw Exception('O autor da obra é obrigatório.');
    }

    if (categoriaFinal.isEmpty) {
      throw Exception('A categoria da obra é obrigatória.');
    }

    if (arquivoPdf.isEmpty) {
      throw Exception('É necessário selecionar um documento PDF.');
    }

    if (nomeArquivoFinal.isEmpty) {
      throw Exception('O nome do arquivo é obrigatório.');
    }

    if (!_ehPdf(nomeArquivoFinal)) {
      throw Exception(
        'Apenas arquivos PDF são permitidos.',
      );
    }

    // ----------------------------------------------------------
    // UPLOAD DO PDF
    // ----------------------------------------------------------

    String? caminhoDocumento;

    try {
      caminhoDocumento =
      await _storage.enviarDocumentoPendente(
        bytes: arquivoPdf,
        nomeArquivo: nomeArquivoFinal,
        userId: userId,
      );

      // --------------------------------------------------------
      // CRIAR REGISTRO EM OBRAS PENDENTES
      // --------------------------------------------------------

      final obra = ObraPendente(
        titulo: tituloFinal,
        descricao: descricaoFinal == null ||
            descricaoFinal.isEmpty
            ? null
            : descricaoFinal,
        autor: autorFinal,
        categoria: categoriaFinal,
        urlDocumento: caminhoDocumento,
        anoObra: anoObra,
        userId: userId,
      );

      return await _repository.inserir(obra);
    } catch (e) {
      // --------------------------------------------------------
      // LIMPAR PDF CASO A GRAVAÇÃO FALHE
      // --------------------------------------------------------

      if (caminhoDocumento != null) {
        try {
          await _storage.removerDocumentoPendente(
            caminhoDocumento,
          );
        } catch (_) {
          // Não substituir o erro original.
        }
      }

      rethrow;
    }
  }

  // ============================================================
  // VALIDAR PDF
  // ============================================================

  bool _ehPdf(String nomeArquivo) {
    return nomeArquivo
        .toLowerCase()
        .endsWith('.pdf');
  }
}

