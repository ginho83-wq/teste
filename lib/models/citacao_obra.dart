class CitacaoObra { final int id; final String obraId; final String? userId; final String textoCitacao; final DateTime? dataCriacao; final String? tipoCitacao; final String? urlCitacao;
const CitacaoObra({ this.id = 0, required this.obraId, this.userId, required this.textoCitacao, this.dataCriacao, this.tipoCitacao, this.urlCitacao, });
factory CitacaoObra.fromMap(Map<String, dynamic> map) { final idValor = map['id'];
return CitacaoObra(
  id: idValor is num
      ? idValor.toInt()
      : int.tryParse(idValor?.toString() ?? '') ?? 0,
  obraId: map['obra_id']?.toString() ?? '',
  userId: map['user_id']?.toString(),
  textoCitacao: map['texto_citacao']?.toString() ?? '',
  dataCriacao: map['data_criacao'] == null
      ? null
      : DateTime.tryParse(
    map['data_criacao'].toString(),
  ),
  tipoCitacao: map['tipo_citacao']?.toString(),
  urlCitacao: map['url_citacao']?.toString(),
);
}
Map<String, dynamic> toMap({ bool incluirId = false, }) { final mapa = <String, dynamic>{ 'obra_id': obraId, 'user_id': userId, 'texto_citacao': textoCitacao, 'data_criacao': dataCriacao?.toUtc().toIso8601String(), 'tipo_citacao': tipoCitacao, 'url_citacao': urlCitacao, };
if (incluirId && id > 0) {
  mapa['id'] = id;
}

return mapa;
} }

