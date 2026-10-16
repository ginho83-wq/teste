import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/estatisticas_obra.dart';

class EstatisticasObrasService {
  EstatisticasObrasService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _tabelaObras = 'obras';
  static const String _tabelaEventos = 'obra_eventos';
  static const String _funcaoRegistarEvento = 'registar_obra_evento';

  static const String _eventoVisualizacao = 'visualizacao';
  static const String _eventoCliquePdf = 'clique_pdf';

  // =========================================================
  // UTILIZADOR AUTENTICADO
  // =========================================================

  String _obterUtilizadorId() {
    final utilizador = _client.auth.currentUser;

    if (utilizador == null) {
      throw Exception(
        'É necessário iniciar sessão para consultar estas estatísticas.',
      );
    }

    return utilizador.id;
  }

  // =========================================================
  // REGISTAR VISUALIZAÇÃO
  // =========================================================

  Future<void> registarVisualizacao(String obraId) async {
    await _registarEvento(
      obraId: obraId,
      tipoEvento: _eventoVisualizacao,
    );
  }

  // =========================================================
  // REGISTAR CLIQUE NO PDF
  // =========================================================

  Future<void> registarCliquePdf(String obraId) async {
    await _registarEvento(
      obraId: obraId,
      tipoEvento: _eventoCliquePdf,
    );
  }

  // =========================================================
  // REGISTAR EVENTO ATRAVÉS DA FUNÇÃO SQL
  // =========================================================

  Future<void> _registarEvento({
    required String obraId,
    required String tipoEvento,
  }) async {
    if (obraId.trim().isEmpty) {
      throw ArgumentError('O identificador da obra é obrigatório.');
    }

    if (tipoEvento != _eventoVisualizacao &&
        tipoEvento != _eventoCliquePdf) {
      throw ArgumentError('Tipo de evento inválido.');
    }

    await _client.rpc(
      _funcaoRegistarEvento,
      params: {
        'p_obra_id': obraId,
        'p_tipo_evento': tipoEvento,
      },
    );
  }

  // =========================================================
  // OBTER ESTATÍSTICAS DE TODAS AS OBRAS DO AUTOR
  // =========================================================

  Future<List<EstatisticasObra>> obterEstatisticasAutor() async {
    final utilizadorId = _obterUtilizadorId();

    // Obter apenas as obras pertencentes ao utilizador autenticado.
    final respostaObras = await _client
        .from(_tabelaObras)
        .select('id, titulo')
        .eq('user_id', utilizadorId)
        .order('titulo');

    final obras = List<Map<String, dynamic>>.from(respostaObras);

    if (obras.isEmpty) {
      return [];
    }

    final idsObras = obras
        .map((obra) => obra['id'].toString())
        .toList();

    // Inicializar as estatísticas de todas as obras.
    final Map<String, Map<String, dynamic>> estatisticas = {};

    for (final obra in obras) {
      final id = obra['id'].toString();

      estatisticas[id] = {
        'obra_id': id,
        'titulo': obra['titulo']?.toString() ?? 'Obra sem título',
        'visualizacoes': 0,
        'cliques_pdf': 0,
        'ultimo_evento': null,
      };
    }

    // Obter os eventos das obras do autor.
    final respostaEventos = await _client
        .from(_tabelaEventos)
        .select('obra_id, tipo_evento, data_evento')
        .inFilter('obra_id', idsObras);

    final eventos = List<Map<String, dynamic>>.from(respostaEventos);

    for (final evento in eventos) {
      final obraId = evento['obra_id']?.toString();

      if (obraId == null || !estatisticas.containsKey(obraId)) {
        continue;
      }

      final dados = estatisticas[obraId]!;
      final tipoEvento = evento['tipo_evento']?.toString();

      if (tipoEvento == _eventoVisualizacao) {
        dados['visualizacoes'] =
            (dados['visualizacoes'] as int) + 1;
      } else if (tipoEvento == _eventoCliquePdf) {
        dados['cliques_pdf'] =
            (dados['cliques_pdf'] as int) + 1;
      }

      final dataEvento = DateTime.tryParse(
        evento['data_evento']?.toString() ?? '',
      );

      if (dataEvento != null) {
        final dataAnterior =
        dados['ultimo_evento'] as DateTime?;

        if (dataAnterior == null ||
            dataEvento.isAfter(dataAnterior)) {
          dados['ultimo_evento'] = dataEvento;
        }
      }
    }

    return estatisticas.values
        .map((dados) => EstatisticasObra.fromMap(dados))
        .toList()
      ..sort((a, b) => b.totalEventos.compareTo(a.totalEventos));
  }

  // =========================================================
  // OBTER ESTATÍSTICAS DE UMA OBRA ESPECÍFICA
  // =========================================================

  Future<EstatisticasObra> obterEstatisticasObra(
      String obraId,
      ) async {
    final utilizadorId = _obterUtilizadorId();

    if (obraId.trim().isEmpty) {
      throw ArgumentError('O identificador da obra é obrigatório.');
    }

    // Confirmar que a obra pertence ao utilizador autenticado.
    final respostaObra = await _client
        .from(_tabelaObras)
        .select('id, titulo')
        .eq('id', obraId)
        .eq('user_id', utilizadorId)
        .maybeSingle();

    if (respostaObra == null) {
      throw Exception(
        'A obra não existe ou não tens autorização para consultar '
            'as suas estatísticas.',
      );
    }

    final respostaEventos = await _client
        .from(_tabelaEventos)
        .select('tipo_evento, data_evento')
        .eq('obra_id', obraId);

    final eventos = List<Map<String, dynamic>>.from(respostaEventos);

    int visualizacoes = 0;
    int cliquesPdf = 0;
    DateTime? ultimoEvento;

    for (final evento in eventos) {
      final tipoEvento = evento['tipo_evento']?.toString();

      if (tipoEvento == _eventoVisualizacao) {
        visualizacoes++;
      } else if (tipoEvento == _eventoCliquePdf) {
        cliquesPdf++;
      }

      final dataEvento = DateTime.tryParse(
        evento['data_evento']?.toString() ?? '',
      );

      if (dataEvento != null &&
          (ultimoEvento == null ||
              dataEvento.isAfter(ultimoEvento))) {
        ultimoEvento = dataEvento;
      }
    }

    return EstatisticasObra(
      obraId: respostaObra['id'].toString(),
      titulo: respostaObra['titulo']?.toString() ?? 'Obra sem título',
      visualizacoes: visualizacoes,
      cliquesPdf: cliquesPdf,
      ultimoEvento: ultimoEvento,
    );
  }
}

