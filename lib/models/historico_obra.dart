class HistoricoObra {
  final String id;
  final String obraId;
  final String userId;
  final DateTime dataConsulta;
  final DateTime createdAt;

  final String titulo;
  final String? autor;
  final String? categoria;
  final String? descricao;
  final String? urlDocumento;

  HistoricoObra({
    required this.id,
    required this.obraId,
    required this.userId,
    required this.dataConsulta,
    required this.createdAt,
    required this.titulo,
    this.autor,
    this.categoria,
    this.descricao,
    this.urlDocumento,
  });

  factory HistoricoObra.fromMap(Map<String, dynamic> map) {
    final obra = map['obras'] is Map<String, dynamic>
        ? map['obras'] as Map<String, dynamic>
        : <String, dynamic>{};

    return HistoricoObra(
      id: map['id'] as String,
      obraId: map['obra_id'] as String,
      userId: map['user_id'] as String,
      dataConsulta: DateTime.parse(map['data_consulta'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      titulo: obra['titulo'] as String? ?? 'Obra sem título',
      autor: obra['autor'] as String?,
      categoria: obra['categoria'] as String?,
      descricao: obra['descricao'] as String?,
      urlDocumento: obra['url_documento'] as String?,
    );
  }
}
