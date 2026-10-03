import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class ArquivoSelecionado {
  final String nome;
  final Uint8List bytes;
  final int tamanho;

  const ArquivoSelecionado({
    required this.nome,
    required this.bytes,
    required this.tamanho,
  });

  /// Tamanho real do arquivo em MB.
  double get tamanhoMb {
    return bytes.length / (1024 * 1024);
  }
}

class ArquivoService {
  ArquivoService._();

  static final ArquivoService instancia =
  ArquivoService._();

  // ============================================================
  // SELECIONAR PDF
  // ============================================================

  Future<ArquivoSelecionado?> selecionarPdf() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,
    );

    if (resultado == null ||
        resultado.files.isEmpty) {
      return null;
    }

    final arquivo = resultado.files.first;

    if (arquivo.bytes == null ||
        arquivo.bytes!.isEmpty) {
      throw Exception(
        'Não foi possível ler o conteúdo do arquivo selecionado.',
      );
    }

    final bytes = arquivo.bytes!;
    final nome = arquivo.name;

    if (!ehPdf(nome)) {
      throw Exception(
        'Selecione apenas arquivos no formato PDF.',
      );
    }

    return ArquivoSelecionado(
      nome: nome,
      bytes: bytes,
      tamanho: bytes.length,
    );
  }

  // ============================================================
  // SELECIONAR IMAGENS
  // ============================================================

  Future<List<ArquivoSelecionado>> selecionarImagens() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
      ],
      allowMultiple: true,
      withData: true,
    );

    if (resultado == null ||
        resultado.files.isEmpty) {
      return [];
    }

    final imagens = <ArquivoSelecionado>[];

    for (final arquivo in resultado.files) {
      if (arquivo.bytes == null ||
          arquivo.bytes!.isEmpty) {
        continue;
      }

      final nome = arquivo.name;
      final bytes = arquivo.bytes!;

      if (!ehImagem(nome)) {
        continue;
      }

      imagens.add(
        ArquivoSelecionado(
          nome: nome,
          bytes: bytes,
          tamanho: bytes.length,
        ),
      );
    }

    return imagens;
  }

  // ============================================================
  // VERIFICAR PDF
  // ============================================================

  bool ehPdf(String nomeArquivo) {
    return nomeArquivo
        .toLowerCase()
        .endsWith('.pdf');
  }

  // ============================================================
  // VERIFICAR IMAGEM
  // ============================================================

  bool ehImagem(String nomeArquivo) {
    final nome = nomeArquivo.toLowerCase();

    return nome.endsWith('.jpg') ||
        nome.endsWith('.jpeg') ||
        nome.endsWith('.png') ||
        nome.endsWith('.webp') ||
        nome.endsWith('.gif');
  }

  // ============================================================
  // TAMANHO EM MB
  // ============================================================

  double tamanhoMb(int tamanhoBytes) {
    return tamanhoBytes / (1024 * 1024);
  }

  // ============================================================
  // FORMATAR TAMANHO
  // ============================================================

  String formatarTamanho(int tamanhoBytes) {
    if (tamanhoBytes < 1024) {
      return '$tamanhoBytes bytes';
    }

    if (tamanhoBytes < 1024 * 1024) {
      final kb = tamanhoBytes / 1024;

      return '${kb.toStringAsFixed(2)} KB';
    }

    final mb = tamanhoBytes / (1024 * 1024);

    return '${mb.toStringAsFixed(2)} MB';
  }

  // ============================================================
  // LIMPAR NOME DO ARQUIVO
  // ============================================================

  String limparNomeArquivo(String nomeArquivo) {
    var nome = nomeArquivo.trim();

    nome = nome.replaceAll(
      RegExp(r'[^\w\s.-]', unicode: true),
      '',
    );

    nome = nome.replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    return nome;
  }
}
