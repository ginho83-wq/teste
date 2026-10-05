class ObraImagem {
  final String? id;
  final String obraId;
  final String urlImagem;
  final String? legenda;
  final String? fonte;
  final String posicao;
  final int ordem;

  const ObraImagem({
    this.id,
    required this.obraId,
    required this.urlImagem,
    this.legenda,
    this.fonte,
    this.posicao = 'dentro_conteudo',
    this.ordem = 1,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory ObraImagem.fromMap(
      Map<String, dynamic> map,
      ) {
    final id =
    map['id']?.toString();

    final obraId =
        map['obra_id']?.toString() ??
            map['obra_pendente_id']
                ?.toString() ??
            '';

    String urlImagem = '';

    final valorUrl =
    map['url_imagem'];

    if (valorUrl != null &&
        valorUrl.toString().trim().isNotEmpty) {
      urlImagem =
          valorUrl.toString().trim();
    } else {
      final valorCaminho =
      map['caminho_imagem'];

      if (valorCaminho != null &&
          valorCaminho
              .toString()
              .trim()
              .isNotEmpty) {
        urlImagem =
            valorCaminho.toString().trim();
      }
    }

    // ==========================================================
    // LEGENDA
    // ==========================================================

    final legenda =
    map['legenda']?.toString();

    // ==========================================================
    // FONTE
    // ==========================================================

    final fonte =
    map['fonte']?.toString();

    // ==========================================================
    // POSIÇÃO
    // ==========================================================

    final posicao =
        map['posicao']?.toString() ??
            'dentro_conteudo';

    // ==========================================================
    // ORDEM
    // ==========================================================

    final ordem =
    map['ordem'] != null
        ? int.tryParse(
      map['ordem'].toString(),
    ) ??
        1
        : 1;

    return ObraImagem(
      id: id,
      obraId: obraId,
      urlImagem: urlImagem,
      legenda: legenda,
      fonte: fonte,
      posicao: posicao,
      ordem: ordem,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'obra_id': obraId,
      'url_imagem': urlImagem,
      'legenda': legenda,
      'fonte': fonte,
      'posicao': posicao,
      'ordem': ordem,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ObraImagem copyWith({
    String? id,
    String? obraId,
    String? urlImagem,
    String? legenda,
    String? fonte,
    String? posicao,
    int? ordem,
  }) {
    return ObraImagem(
      id: id ?? this.id,
      obraId: obraId ?? this.obraId,
      urlImagem:
      urlImagem ?? this.urlImagem,
      legenda:
      legenda ?? this.legenda,
      fonte:
      fonte ?? this.fonte,
      posicao:
      posicao ?? this.posicao,
      ordem:
      ordem ?? this.ordem,
    );
  }
}

