class ObraPendente {
  final String id;
  final String titulo;
  final String? descricao;
  final String autor;
  final String categoria;
  final String urlDocumento;
  final int? anoObra;
  final DateTime dataPublicacao;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ObraPendente({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.autor,
    required this.categoria,
    required this.urlDocumento,
    this.anoObra,
    required this.dataPublicacao,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ObraPendente.fromMap(Map<String, dynamic> map) {
    return ObraPendente(
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
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
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
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ObraPendente(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      autor: autor ?? this.autor,
      categoria: categoria ?? this.categoria,
      urlDocumento: urlDocumento ?? this.urlDocumento,
      anoObra: anoObra ?? this.anoObra,
      dataPublicacao: dataPublicacao ?? this.dataPublicacao,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

