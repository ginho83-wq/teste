import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pdfx/pdfx.dart';

import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import '../repositories/obras_repository.dart';
import 'arquivo_service.dart';
import 'auth_service.dart';
import 'imagens_storage_service.dart';
import 'storage_service.dart';

class PublicacaoService {
  PublicacaoService._();

  static final PublicacaoService instancia =
  PublicacaoService._();

  final AuthService _authService =
      AuthService.instancia;

  final StorageService _storageService =
      StorageService.instancia;

  final ImagensStorageService
  _imagensStorageService =
      ImagensStorageService.instancia;

  final ObrasPendentesRepository
  _pendentesRepository =
      ObrasPendentesRepository.instancia;

  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  // ============================================================
  // PUBLICAR
  // ============================================================

  Future<ObraPendente> publicar({
    required String titulo,
    String? descricao,
    required String autor,
    required String categoria,
    required Uint8List arquivoPdf,
    required String nomeArquivo,
    int? anoObra,
    List<Map<String, dynamic>> secoes =
    const [],
    List<ArquivoSelecionado> imagens =
    const [],
  }) async {
    final usuario =
        _authService.usuarioAtual;

    if (usuario == null) {
      throw Exception(
        'É necessário iniciar sessão para publicar.',
      );
    }

    final tituloLimpo =
    titulo.trim();

    final autorLimpo =
    autor.trim();

    final categoriaLimpa =
    categoria.trim();

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
        'Informe a categoria da obra.',
      );
    }

    if (arquivoPdf.isEmpty) {
      throw Exception(
        'Selecione um ficheiro PDF.',
      );
    }

    if (nomeArquivo.trim().isEmpty) {
      throw Exception(
        'O nome do ficheiro PDF é obrigatório.',
      );
    }

    // ==========================================================
    // LIMPAR SECÇÕES
    // ==========================================================

    final secoesLimpa =
    <Map<String, dynamic>>[];

    for (
    var i = 0;
    i < secoes.length;
    i++
    ) {
      final secao = secoes[i];

      final tituloSecao =
          secao['titulo']
              ?.toString()
              .trim() ??
              '';

      final conteudoSecao =
          secao['conteudo']
              ?.toString()
              .trim() ??
              '';

      if (tituloSecao.isEmpty &&
          conteudoSecao.isEmpty) {
        continue;
      }

      final ordem =
          int.tryParse(
            secao['ordem']
                ?.toString() ??
                '',
          ) ??
              (i + 1);

      final nivel =
          int.tryParse(
            secao['nivel']
                ?.toString() ??
                '',
          ) ??
              1;

      secoesLimpa.add({
        'titulo': tituloSecao,
        'conteudo': conteudoSecao,
        'ordem': ordem,
        'nivel': nivel,
      });
    }

    // ==========================================================
    // VALIDAR IMAGENS
    // ==========================================================

    for (final imagem in imagens) {
      if (imagem.bytes.isEmpty) {
        throw Exception(
          'Uma das imagens selecionadas está vazia.',
        );
      }

      if (!_ehImagem(imagem.nome)) {
        throw Exception(
          'O arquivo "${imagem.nome}" não é uma '
              'imagem válida.',
        );
      }
    }

    // ==========================================================
    // HASH DO PDF
    // ==========================================================

    final hashPdf =
    sha256.convert(arquivoPdf).toString();

    // ==========================================================
    // DUPLICADO PUBLICADO
    // ==========================================================

    final existePublicada =
    await _obrasRepository.existeDuplicado(
      titulo: tituloLimpo,
      autor: autorLimpo,
      nomeArquivo: nomeArquivo,
      hashPdf: hashPdf,
    );

    if (existePublicada) {
      throw Exception(
        'Esta obra já foi publicada na plataforma.',
      );
    }

    // ==========================================================
    // DUPLICADO PENDENTE
    // ==========================================================

    final existePendente =
    await _pendentesRepository
        .existeDuplicado(
      hashPdf,
    );

    if (existePendente) {
      throw Exception(
        'Esta obra já está aguardando aprovação.',
      );
    }

    // ==========================================================
    // DATA
    // ==========================================================

    final dataPublicacao =
    DateTime.now();

    // ==========================================================
    // ENVIAR PDF
    // ==========================================================

    final caminhoPendente =
    await _storageService
        .enviarDocumentoPendente(
      userId: usuario.id,
      nomeArquivo: nomeArquivo,
      bytes: arquivoPdf,
    );

    // ==========================================================
    // PÁGINAS
    // ==========================================================

    int? numeroPaginas;

    try {
      final documento =
      await PdfDocument.openData(
        arquivoPdf,
      );

      numeroPaginas =
          documento.pagesCount;

      await documento.close();
    } catch (_) {
      numeroPaginas = null;
    }

    // ==========================================================
    // TAMANHO
    // ==========================================================

    final tamanhoArquivoBytes =
        arquivoPdf.length;

    // ==========================================================
    // SECÇÕES
    // ==========================================================

    String? conteudoTexto;

    if (secoesLimpa.isNotEmpty) {
      conteudoTexto =
          jsonEncode(
            secoesLimpa,
          );
    }

    // ==========================================================
    // CRIAR OBRA PENDENTE
    // ==========================================================

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

      anoObra: anoObra,

      dataPublicacao:
      dataPublicacao,

      userId: usuario.id,

      numeroPaginas:
      numeroPaginas,

      tamanhoArquivoBytes:
      tamanhoArquivoBytes,

      hashPdf:
      hashPdf,

      conteudoTexto:
      conteudoTexto,
    );

    final obraPendente =
    await _pendentesRepository.inserir(
      obra,
    );

    // ==========================================================
    // GARANTIR ID
    // ==========================================================

    final obraPendenteId =
        obraPendente.id;

    if (obraPendenteId == null ||
        obraPendenteId.trim().isEmpty) {
      throw Exception(
        'Não foi possível obter o ID da obra pendente.',
      );
    }

    // ==========================================================
    // IMAGENS PENDENTES
    // ==========================================================

    final caminhosImagensEnviadas =
    <String>[];

    try {
      for (
      var i = 0;
      i < imagens.length;
      i++
      ) {
        final imagem =
        imagens[i];

        // ------------------------------------------------------
        // UPLOAD
        // ------------------------------------------------------

        final caminho =
        await _imagensStorageService
            .enviarImagemPendente(
          obraPendenteId:
          obraPendenteId,
          nomeArquivo:
          imagem.nome,
          bytes:
          imagem.bytes,
        );

        caminhosImagensEnviadas.add(
          caminho,
        );

        // ------------------------------------------------------
        // INSERT
        // ------------------------------------------------------

        await _pendentesRepository
            .inserirImagemPendente(
          obraPendenteId:
          obraPendenteId,
          caminhoImagem:
          caminho,
          ordem:
          i + 1,
        );
      }
    } catch (e) {
      // ========================================================
      // LIMPAR OBRA E IMAGENS
      // ========================================================

      try {
        await _pendentesRepository
            .rejeitar(
          obraPendenteId,
        );
      } catch (_) {}

      // ========================================================
      // REMOVER ARQUIVOS QUE FORAM ENVIADOS
      // ========================================================

      for (
      final caminho
      in caminhosImagensEnviadas
      ) {
        try {
          await _imagensStorageService
              .removerImagemPendente(
            caminho,
          );
        } catch (_) {}
      }

      rethrow;
    }

    return obraPendente;
  }

  // ============================================================
  // VERIFICAR IMAGEM
  // ============================================================

  bool _ehImagem(
      String nomeArquivo,
      ) {
    final nome =
    nomeArquivo.toLowerCase();

    return nome.endsWith('.jpg') ||
        nome.endsWith('.jpeg') ||
        nome.endsWith('.png') ||
        nome.endsWith('.webp') ||
        nome.endsWith('.gif');
  }
}
