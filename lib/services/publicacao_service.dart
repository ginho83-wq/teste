import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

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
      throw Exception(
        'É necessário estar autenticado para publicar.',
      );
    }

    final tituloLimpo = titulo.trim();
    final autorLimpo = autor.trim();
    final categoriaLimpa = categoria.trim();
    final nomeArquivoLimpo = nomeArquivo.trim();

    if (tituloLimpo.isEmpty) {
      throw Exception(
        'Informe o título da obra.',
      );
    }

    if (autorLimpo.isEmpty) {
      throw Exception(
        'Informe o autor da obra.',
      );
    }

    if (categoriaLimpa.isEmpty) {
      throw Exception(
        'Selecione a categoria da obra.',
      );
    }

    if (arquivoPdf.isEmpty) {
      throw Exception(
        'O arquivo PDF está vazio.',
      );
    }

    if (!nomeArquivoLimpo
        .toLowerCase()
        .endsWith('.pdf')) {
      throw Exception(
        'O arquivo selecionado deve estar no formato PDF.',
      );
    }

    final tamanhoArquivoBytes =
        arquivoPdf.length;

    String? caminhoPendente;
    String? caminhoCapaPendente;

    try {
      // ==========================================================
      // 1. ENVIAR PDF PARA PENDENTES
      // ==========================================================

      caminhoPendente =
      await _storage.enviarDocumentoPendente(
        userId: usuario.id,
        nomeArquivo: nomeArquivoLimpo,
        bytes: arquivoPdf,
      );

      // ==========================================================
      // 2. GERAR CAPA E OBTER NÚMERO DE PÁGINAS
      // ==========================================================

      final resultadoCapa =
      await _gerarCapa(arquivoPdf);

      final bytesCapa =
          resultadoCapa.bytes;

      final numeroPaginas =
          resultadoCapa.numeroPaginas;

      // ==========================================================
      // 3. ENVIAR CAPA PARA CAPAS-PENDENTES
      // ==========================================================

      caminhoCapaPendente =
      await _storage.enviarCapaPendente(
        userId: usuario.id,
        nomeArquivo: nomeArquivoLimpo,
        bytes: bytesCapa,
      );

      // ==========================================================
      // 4. CRIAR REGISTRO PENDENTE
      // ==========================================================

      final dataPublicacao =
      DateTime.now();

      final obra = ObraPendente(
        titulo: tituloLimpo,

        descricao:
        descricao?.trim().isEmpty == true
            ? null
            : descricao?.trim(),

        autor: autorLimpo,

        categoria: categoriaLimpa,

        urlDocumento:
        caminhoPendente,

        urlCapa:
        caminhoCapaPendente,

        anoObra:
        anoObra,

        dataPublicacao:
        dataPublicacao,

        userId:
        usuario.id,

        // NOVO:
        numeroPaginas:
        numeroPaginas,

        tamanhoArquivoBytes:
        tamanhoArquivoBytes,
      );

      return await _repository.inserir(
        obra,
      );
    } catch (e) {
      // ==========================================================
      // LIMPEZA DO PDF SE HOUVER ERRO
      // ==========================================================

      if (caminhoPendente != null) {
        try {
          await _storage
              .removerDocumentoPendente(
            caminhoPendente,
          );
        } catch (_) {}
      }

      // ==========================================================
      // LIMPEZA DA CAPA SE HOUVER ERRO
      // ==========================================================

      if (caminhoCapaPendente != null) {
        try {
          await _storage
              .removerCapaPendente(
            caminhoCapaPendente,
          );
        } catch (_) {}
      }

      rethrow;
    }
  }

  // ==============================================================
  // GERAR CAPA A PARTIR DA PRIMEIRA PÁGINA
  // E OBTER O NÚMERO TOTAL DE PÁGINAS
  // ==============================================================

  Future<_ResultadoCapa> _gerarCapa(
      Uint8List pdfBytes,
      ) async {
    PdfDocument? documento;
    PdfPage? pagina;

    try {
      documento =
      await PdfDocument.openData(
        pdfBytes,
      );

      final numeroPaginas =
          documento.pagesCount;

      if (numeroPaginas < 1) {
        throw Exception(
          'O PDF não possui nenhuma página.',
        );
      }

      pagina =
      await documento.getPage(1);

      final imagem =
      await pagina.render(
        width: pagina.width * 2,
        height: pagina.height * 2,
        format:
        PdfPageImageFormat.png,
        backgroundColor:
        '#FFFFFF',
      );

      if (imagem == null ||
          imagem.bytes.isEmpty) {
        throw Exception(
          'Não foi possível gerar a capa do PDF.',
        );
      }

      return _ResultadoCapa(
        bytes: imagem.bytes,
        numeroPaginas: numeroPaginas,
      );
    } finally {
      await pagina?.close();
      await documento?.close();
    }
  }
}

// ==============================================================
// RESULTADO DA GERAÇÃO DA CAPA
// ==============================================================

class _ResultadoCapa {
  final Uint8List bytes;
  final int numeroPaginas;

  const _ResultadoCapa({
    required this.bytes,
    required this.numeroPaginas,
  });
}
