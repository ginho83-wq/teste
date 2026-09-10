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

  double get tamanhoMb {
    return tamanho / (1024 * 1024);
  }
}

class ArquivoService {
  ArquivoService._();

  static final ArquivoService instancia = ArquivoService._();

  Future<ArquivoSelecionado?> selecionarPdf() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,
    );

    if (resultado == null || resultado.files.isEmpty) {
      return null;
    }

    final arquivo = resultado.files.first;

    if (arquivo.bytes == null || arquivo.bytes!.isEmpty) {
      throw Exception(
        'Não foi possível ler o conteúdo do arquivo selecionado.',
      );
    }

    final nome = arquivo.name;

    if (!ehPdf(nome)) {
      throw Exception(
        'Selecione apenas arquivos no formato PDF.',
      );
    }

    return ArquivoSelecionado(
      nome: nome,
      bytes: arquivo.bytes!,
      tamanho: arquivo.size,
    );
  }

  bool ehPdf(String nomeArquivo) {
    return nomeArquivo.toLowerCase().endsWith('.pdf');
  }

  double tamanhoMb(int tamanhoBytes) {
    return tamanhoBytes / (1024 * 1024);
  }

  String formatarTamanho(int tamanhoBytes) {
    final mb = tamanhoMb(tamanhoBytes);

    if (mb < 1) {
      final kb = tamanhoBytes / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }

    return '${mb.toStringAsFixed(2)} MB';
  }

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

