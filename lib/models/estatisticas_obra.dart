class EstatisticasObra {
  final String obraId;
  final String titulo;
  final int visualizacoes;
  final int cliquesPdf;
  final DateTime? ultimoEvento;

  const EstatisticasObra({
    required this.obraId,
    required this.titulo,
    required this.visualizacoes,
    required this.cliquesPdf,
    this.ultimoEvento,
  });

  int get totalEventos => visualizacoes + cliquesPdf;

  factory EstatisticasObra.fromMap(Map<String, dynamic> map) {
    return EstatisticasObra(
      obraId: map['obra_id']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? 'Obra sem título',
      visualizacoes: _converterInteiro(map['visualizacoes']),
      cliquesPdf: _converterInteiro(map['cliques_pdf']),
      ultimoEvento: _converterData(map['ultimo_evento']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'obra_id': obraId,
      'titulo': titulo,
      'visualizacoes': visualizacoes,
      'cliques_pdf': cliquesPdf,
      'ultimo_evento': ultimoEvento?.toIso8601String(),
    };
  }

  static int _converterInteiro(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static DateTime? _converterData(dynamic valor) {
    if (valor == null) return null;

    if (valor is DateTime) {
      return valor;
    }

    return DateTime.tryParse(valor.toString());
  }
}

