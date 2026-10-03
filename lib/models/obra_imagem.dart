class ObraImagem {
  final String? id;
  final String obraId;
  final String urlImagem;
  final String? legenda;
  final String posicao;
  final int ordem;

  const ObraImagem({
    this.id,
    required this.obraId,
    required this.urlImagem,
    this.legenda,
    this.posicao = 'dentro_conteudo',
    this.ordem = 1,
  });

  factory ObraImagem.fromMap(
      Map<String, dynamic> map,
      ) {
    return ObraImagem(
      id: map['id']?.toString(),

      obraId:
      map['obra_id'].toString(),

      urlImagem:
      map['url_imagem']?.toString() ?? '',

      legenda:
      map['legenda']?.toString(),

      posicao:
      map['posicao']?.toString() ??
          'dentro_conteudo',

      ordem:
      map['ordem'] != null
          ? int.tryParse(
        map['ordem'].toString(),
      ) ??
          1
          : 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'obra_id': obraId,
      'url_imagem': urlImagem,
      'legenda': legenda,
      'posicao': posicao,
      'ordem': ordem,
    };
  }

  ObraImagem copyWith({
    String? id,
    String? obraId,
    String? urlImagem,
    String? legenda,
    String? posicao,
    int? ordem,
  }) {
    return ObraImagem(
      id: id ?? this.id,
      obraId: obraId ?? this.obraId,
      urlImagem: urlImagem ?? this.urlImagem,
      legenda: legenda ?? this.legenda,
      posicao: posicao ?? this.posicao,
      ordem: ordem ?? this.ordem,
    );
  }
}
