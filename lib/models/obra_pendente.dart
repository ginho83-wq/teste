class ObraPendente {
  final String? id;
  final String titulo;
  final String? descricao;
  final String autor;
  final String categoria;
  final String urlDocumento;
  final int? anoObra;
  final DateTime dataPublicacao;
  final String userId;
  final int? numeroPaginas;
  final int? tamanhoArquivoBytes;
  final String? hashPdf;
  final String? conteudoTexto;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ObraPendente({
    this.id,
    required this.titulo,
    this.descricao,
    required this.autor,
    required this.categoria,
    required this.urlDocumento,
    this.anoObra,
    required this.dataPublicacao,
    required this.userId,
    this.numeroPaginas,
    this.tamanhoArquivoBytes,
    this.hashPdf,
    this.conteudoTexto,
    this.createdAt,
    this.updatedAt,
  });

  factory ObraPendente.fromMap(
      Map<String, dynamic> map,
      ) {
    return ObraPendente(
      id: map['id']?.toString(),

      titulo: map['titulo']?.toString() ?? '',

      descricao: map['descricao']?.toString(),

      autor: map['autor']?.toString() ?? '',

      categoria: map['categoria']?.toString() ?? '',

      urlDocumento:
      map['url_documento']?.toString() ?? '',

      anoObra: map['ano_obra'] != null
          ? int.tryParse(
        map['ano_obra'].toString(),
      )
          : null,

      dataPublicacao: DateTime.parse(
        map['data_publicacao'].toString(),
      ),

      userId: map['user_id']?.toString() ?? '',

      numeroPaginas: map['numero_paginas'] != null
          ? int.tryParse(
        map['numero_paginas'].toString(),
      )
          : null,

      tamanhoArquivoBytes:
      map['tamanho_arquivo_bytes'] != null
          ? int.tryParse(
        map['tamanho_arquivo_bytes']
            .toString(),
      )
          : null,

      hashPdf: map['hash_pdf']?.toString(),

      conteudoTexto:
      map['conteudo_texto']?.toString(),

      createdAt: map['created_at'] != null
          ? DateTime.parse(
        map['created_at'].toString(),
      )
          : null,

      updatedAt: map['updated_at'] != null
          ? DateTime.parse(
        map['updated_at'].toString(),
      )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,

      'titulo': titulo,

      'descricao': descricao,

      'autor': autor,

      'categoria': categoria,

      'url_documento': urlDocumento,

      'ano_obra': anoObra,

      'data_publicacao':
      dataPublicacao.toIso8601String(),

      'user_id': userId,

      'numero_paginas': numeroPaginas,

      'tamanho_arquivo_bytes':
      tamanhoArquivoBytes,

      'hash_pdf': hashPdf,

      'conteudo_texto': conteudoTexto,

      if (createdAt != null)
        'created_at':
        createdAt!.toIso8601String(),

      if (updatedAt != null)
        'updated_at':
        updatedAt!.toIso8601String(),
    };
  }

  ObraPendente copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? autor,
    String? categoria,
    String? urlDocumento,
    int? anoObra,
    DateTime? dataPublicacao,
    String? userId,
    int? numeroPaginas,
    int? tamanhoArquivoBytes,
    String? hashPdf,
    String? conteudoTexto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ObraPendente(
      id: id ?? this.id,

      titulo: titulo ?? this.titulo,

      descricao: descricao ?? this.descricao,

      autor: autor ?? this.autor,

      categoria: categoria ?? this.categoria,

      urlDocumento:
      urlDocumento ?? this.urlDocumento,

      anoObra: anoObra ?? this.anoObra,

      dataPublicacao:
      dataPublicacao ?? this.dataPublicacao,

      userId: userId ?? this.userId,

      numeroPaginas:
      numeroPaginas ?? this.numeroPaginas,

      tamanhoArquivoBytes:
      tamanhoArquivoBytes ??
          this.tamanhoArquivoBytes,

      hashPdf: hashPdf ?? this.hashPdf,

      conteudoTexto:
      conteudoTexto ?? this.conteudoTexto,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
