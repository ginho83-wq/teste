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

  // Tamanho real do PDF em bytes.
  final int? tamanhoArquivoBytes;

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
    this.tamanhoArquivoBytes,
    this.createdAt,
    this.updatedAt,
  });

  factory ObraPendente.fromMap(
      Map<String, dynamic> map,
      ) {
    return ObraPendente(
      id: map['id']?.toString(),

      titulo:
      map['titulo']?.toString() ?? '',

      descricao:
      map['descricao']?.toString(),

      autor:
      map['autor']?.toString() ?? '',

      categoria:
      map['categoria']?.toString() ?? '',

      urlDocumento:
      map['url_documento']?.toString() ?? '',

      anoObra:
      _parseInt(map['ano_obra']),

      dataPublicacao:
      _parseDate(map['data_publicacao']) ??
          DateTime.now(),

      userId:
      map['user_id']?.toString() ?? '',

      // Lê o tamanho real armazenado no banco.
      tamanhoArquivoBytes:
      _parseInt(
        map['tamanho_arquivo_bytes'],
      ),

      createdAt:
      _parseDate(map['created_at']),

      updatedAt:
      _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null)
        'id': id,

      'titulo': titulo,

      'descricao': descricao,

      'autor': autor,

      'categoria': categoria,

      'url_documento': urlDocumento,

      'ano_obra': anoObra,

      'data_publicacao':
      dataPublicacao.toIso8601String(),

      'user_id': userId,

      // Guarda o tamanho real.
      'tamanho_arquivo_bytes':
      tamanhoArquivoBytes,

      'created_at':
      createdAt?.toIso8601String(),

      'updated_at':
      updatedAt?.toIso8601String(),
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
    int? tamanhoArquivoBytes,
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
      anoObra:
      anoObra ?? this.anoObra,
      dataPublicacao:
      dataPublicacao ?? this.dataPublicacao,
      userId:
      userId ?? this.userId,

      tamanhoArquivoBytes:
      tamanhoArquivoBytes ??
          this.tamanhoArquivoBytes,

      createdAt:
      createdAt ?? this.createdAt,

      updatedAt:
      updatedAt ?? this.updatedAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}
