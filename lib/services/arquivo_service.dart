import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class ArquivoSelecionado {
  final Uint8List bytes;
  final String nome;
  final int tamanho;

  const ArquivoSelecionado({
    required this.bytes,
    required this.nome,
    required this.tamanho,
  });

  double get tamanhoMb {
    return tamanho / (1024 * 1024);
  }
}

class ArquivoService {
  ArquivoService._();

  static final ArquivoService instancia =
      ArquivoService._();

  // ============================================================
  // LIMITE DO ARQUIVO
  // ============================================================

  static const int tamanhoMaximoMb = 50;

  static const int tamanhoMaximoBytes =
      tamanhoMaximoMb * 1024 * 1024;

  // ============================================================
  // SELECIONAR PDF
  // ============================================================

  Future<ArquivoSelecionado?> selecionarPdf() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
      allowMultiple: false,
    );

    // Utilizador cancelou a seleção.
    if (resultado == null ||
        resultado.files.isEmpty) {
      return null;
    }

    final arquivo = resultado.files.first;

    // ----------------------------------------------------------
    // VERIFICAR EXTENSÃO
    // ----------------------------------------------------------

    final nome = arquivo.name.trim();

    if (!nome.toLowerCase().endsWith('.pdf')) {
      throw Exception(
        'Apenas arquivos PDF são permitidos.',
      );
    }

    // ----------------------------------------------------------
    // VERIFICAR TAMANHO
    // ----------------------------------------------------------

    if (arquivo.size > tamanhoMaximoBytes) {
      throw Exception(
        'O PDF não pode ultrapassar '
        '$tamanhoMaximoMb MB.',
      );
    }

    // ----------------------------------------------------------
    // OBTER BYTES
    // ----------------------------------------------------------

    final bytes = arquivo.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception(
        'Não foi possível ler o arquivo selecionado.',
      );
    }

    return ArquivoSelecionado(
      bytes: bytes,
      nome: nome,
      tamanho: arquivo.size,
    );
  }
}

