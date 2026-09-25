class Comentario {
  final String id;
  final String obraId;
  final String userId;
  final String comentario;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comentario({
    required this.id,
    required this.obraId,
    required this.userId,
    required this.comentario,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comentario.fromMap(Map<String, dynamic> map) {
    return Comentario(
      id: map['id'] as String,
      obraId: map['obra_id'] as String,
      userId: map['user_id'] as String,
      comentario: map['comentario'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'obra_id': obraId,
      'user_id': userId,
      'comentario': comentario,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

