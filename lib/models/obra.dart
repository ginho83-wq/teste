class Obra {
  final String id;
  final String titulo;
  final String? descricao;
  final String autor;
  final String categoria;
  final String urlDocumento;
  final int? anoObra;
  final DateTime dataPublicacao;
  final int? numeroPaginas;
  final int? tamanhoArquivoBytes;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Obra({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.autor,
    required this.categoria,
    required this.urlDocumento,
    this.anoObra,
    required this.dataPublicacao,
    this.numeroPaginas,
    this.tamanhoArquivoBytes,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Obra.fromMap(Map<String, dynamic> map) {
    return Obra(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      descricao: map['descricao'] as String?,
      autor: map['autor'] as String,
      categoria: map['categoria'] as String,
      urlDocumento: map['url_documento'] as String,
      anoObra: map['ano_obra'] != null
          ? int.tryParse(map['ano_obra'].toString())
          : null,
      dataPublicacao:
      DateTime.parse(map['data_publicacao'].toString()),
      numeroPaginas: map['numero_paginas'] != null
          ? int.tryParse(map['numero_paginas'].toString())
          : null,
      tamanhoArquivoBytes: map['tamanho_arquivo_bytes'] != null
          ? int.tryParse(
        map['tamanho_arquivo_bytes'].toString(),
      )
          : null,
      userId: map['user_id'] as String,
      createdAt:
      DateTime.parse(map['created_at'].toString()),
      updatedAt:
      DateTime.parse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'autor': autor,
      'categoria': categoria,
      'url_documento': urlDocumento,
      'ano_obra': anoObra,
      'data_publicacao': dataPublicacao.toIso8601String(),
      'numero_paginas': numeroPaginas,
      'tamanho_arquivo_bytes': tamanhoArquivoBytes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Obra copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? autor,
    String? categoria,
    String? urlDocumento,
    int? anoObra,
    DateTime? dataPublicacao,
    int? numeroPaginas,
    int? tamanhoArquivoBytes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Obra(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      autor: autor ?? this.autor,
      categoria: categoria ?? this.categoria,
      urlDocumento: urlDocumento ?? this.urlDocumento,
      anoObra: anoObra ?? this.anoObra,
      dataPublicacao:
      dataPublicacao ?? this.dataPublicacao,
      numeroPaginas:
      numeroPaginas ?? this.numeroPaginas,
      tamanhoArquivoBytes:
      tamanhoArquivoBytes ?? this.tamanhoArquivoBytes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

