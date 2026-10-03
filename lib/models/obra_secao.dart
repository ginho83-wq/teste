class ObraSecao {
  final String id;
  final String obraId;
  final String titulo;
  final String? conteudo;
  final int ordem;
  final int nivel;

  const ObraSecao({
    required this.id,
    required this.obraId,
    required this.titulo,
    this.conteudo,
    required this.ordem,
    required this.nivel,
  });

  factory ObraSecao.fromMap(Map<String, dynamic> map) {
    return ObraSecao(
      id: map['id'].toString(),
      obraId: map['obra_id'].toString(),
      titulo: map['titulo']?.toString() ?? '',
      conteudo: map['conteudo']?.toString(),
      ordem: int.tryParse(
        map['ordem']?.toString() ?? '',
      ) ??
          1,
      nivel: int.tryParse(
        map['nivel']?.toString() ?? '',
      ) ??
          1,
    );
  }
}

