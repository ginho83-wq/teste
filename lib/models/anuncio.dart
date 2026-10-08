class Anuncio {
  final String id;
  final String titulo;
  final String tipo;
  final String? urlImagem;
  final String? urlVideo;
  final String? linkDestino;
  final bool ativo;
  final String posicao;
  final int ordem;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  const Anuncio({
    required this.id,
    required this.titulo,
    required this.tipo,
    this.urlImagem,
    this.urlVideo,
    this.linkDestino,
    required this.ativo,
    required this.posicao,
    required this.ordem,
    this.dataInicio,
    this.dataFim,
  });

  factory Anuncio.fromMap(Map<String, dynamic> map) {
    return Anuncio(
      id: map['id']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? 'fixo',
      urlImagem: map['url_imagem']?.toString(),
      urlVideo: map['url_video']?.toString(),
      linkDestino: map['link_destino']?.toString(),
      ativo: map['ativo'] == true,
      posicao: map['posicao']?.toString() ?? 'lateral',
      ordem: map['ordem'] is int
          ? map['ordem'] as int
          : int.tryParse(map['ordem']?.toString() ?? '') ?? 1,
      dataInicio: _parseDate(map['data_inicio']),
      dataFim: _parseDate(map['data_fim']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  bool get estaDisponivel {
    if (!ativo) return false;

    final agora = DateTime.now();

    if (dataInicio != null && agora.isBefore(dataInicio!)) {
      return false;
    }

    if (dataFim != null && agora.isAfter(dataFim!)) {
      return false;
    }

    return true;
  }

  bool get ehVideo => tipo.toLowerCase() == 'video';

  bool get ehFixo => tipo.toLowerCase() == 'fixo';
}
