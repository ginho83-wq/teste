import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/citacao_obra.dart';

class CitacoesObrasService {
  CitacoesObrasService._internal();

  static final CitacoesObrasService instance =
  CitacoesObrasService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _tabela = 'citacoes_obras';

  /// Normas bibliográficas disponíveis.
  static const List<String> normasDisponiveis = [
    'APA 7',
    'ABNT',
    'Vancouver',
    'IEEE',
    'ISO 690',
  ];

  /// Gera uma referência bibliográfica de acordo com a norma selecionada.
  ///
  /// Os campos disponíveis são título, autor, ano e URL.
  /// Quando algum campo não está disponível, a referência é simplificada.
  String gerarCitacao({
    required String norma,
    required String titulo,
    required String autor,
    int? ano,
    String? url,
  }) {
    final normaNormalizada = norma.trim().toUpperCase();

    final tituloLimpo = titulo.trim().isEmpty
        ? 'Título não identificado'
        : titulo.trim();

    final autorLimpo = autor.trim().isEmpty
        ? 'Autor não identificado'
        : autor.trim();

    final anoTexto = ano == null ? 's.d.' : ano.toString();

    final urlLimpo = url?.trim();

    final temUrl = urlLimpo != null && urlLimpo.isNotEmpty;

    switch (normaNormalizada) {
      case 'APA 7':
      case 'APA7':
        return gerarCitacaoAPA(
          titulo: tituloLimpo,
          autor: autorLimpo,
          ano: ano,
          url: urlLimpo,
        );

      case 'ABNT':
        return _gerarABNT(
          titulo: tituloLimpo,
          autor: autorLimpo,
          ano: ano,
          url: urlLimpo,
        );

      case 'VANCOUVER':
        return _gerarVancouver(
          titulo: tituloLimpo,
          autor: autorLimpo,
          ano: ano,
          url: urlLimpo,
        );

      case 'IEEE':
        return _gerarIEEE(
          titulo: tituloLimpo,
          autor: autorLimpo,
          ano: ano,
          url: urlLimpo,
        );

      case 'ISO 690':
      case 'ISO690':
        return _gerarISO690(
          titulo: tituloLimpo,
          autor: autorLimpo,
          ano: ano,
          url: urlLimpo,
        );

      default:
        throw ArgumentError(
          'Norma bibliográfica não suportada: $norma',
        );
    }
  }

  /// APA 7.ª edição.
  String gerarCitacaoAPA({
    required String titulo,
    required String autor,
    int? ano,
    String? url,
  }) {
    final autorFinal = _formatarAutorAPA(autor);
    final anoFinal = ano?.toString() ?? 's.d.';
    final tituloFinal = _formatarTitulo(titulo);

    final partes = <String>[
      '$autorFinal ($anoFinal). $tituloFinal.',
    ];

    final urlLimpo = url?.trim();

    if (urlLimpo != null && urlLimpo.isNotEmpty) {
      partes.add(urlLimpo);
    }

    return partes.join(' ');
  }

  /// ABNT: referência bibliográfica simplificada.
  ///
  /// O sobrenome é colocado em maiúsculas quando o autor é apresentado
  /// no formato "Nome Sobrenome".
  String _gerarABNT({
    required String titulo,
    required String autor,
    int? ano,
    String? url,
  }) {
    final autorFinal = _formatarAutorABNT(autor);
    final tituloFinal = _formatarTitulo(titulo);
    final anoFinal = ano?.toString() ?? 's.d.';

    final partes = <String>[
      '$autorFinal. $tituloFinal. $anoFinal.',
    ];

    final urlLimpo = url?.trim();

    if (urlLimpo != null && urlLimpo.isNotEmpty) {
      partes.add('Disponível em: $urlLimpo.');
      partes.add('Acesso em: ${_dataAtualFormatada()}.');
    }

    return partes.join(' ');
  }

  /// Vancouver: referência numerada.
  String _gerarVancouver({
    required String titulo,
    required String autor,
    int? ano,
    String? url,
  }) {
    final autorFinal = _formatarAutorVancouver(autor);
    final tituloFinal = _formatarTitulo(titulo);
    final anoFinal = ano?.toString() ?? 's.d.';

    final partes = <String>[
      '$autorFinal. $tituloFinal. $anoFinal.',
    ];

    final urlLimpo = url?.trim();

    if (urlLimpo != null && urlLimpo.isNotEmpty) {
      partes.add('Disponível em: $urlLimpo.');
      partes.add('Acesso em: ${_dataAtualFormatada()}.');
    }

    return partes.join(' ');
  }

  /// IEEE: referência numerada.
  String _gerarIEEE({
    required String titulo,
    required String autor,
    int? ano,
    String? url,
  }) {
    final autorFinal = _formatarAutorIEEE(autor);
    final tituloFinal = _formatarTitulo(titulo);
    final anoFinal = ano?.toString() ?? 's.d.';

    final partes = <String>[
      '$autorFinal, "$tituloFinal," $anoFinal.',
    ];

    final urlLimpo = url?.trim();

    if (urlLimpo != null && urlLimpo.isNotEmpty) {
      partes.add('Disponível em: $urlLimpo.');
      partes.add('Acesso em: ${_dataAtualFormatada()}.');
    }

    return partes.join(' ');
  }

  /// ISO 690: referência bibliográfica simplificada.
  String _gerarISO690({
    required String titulo,
    required String autor,
    int? ano,
    String? url,
  }) {
    final autorFinal = _formatarAutorABNT(autor);
    final tituloFinal = _formatarTitulo(titulo);
    final anoFinal = ano?.toString() ?? 's.d.';

    final partes = <String>[
      '$autorFinal. $tituloFinal. $anoFinal.',
    ];

    final urlLimpo = url?.trim();

    if (urlLimpo != null && urlLimpo.isNotEmpty) {
      partes.add('[Em linha].');
      partes.add('Disponível em: $urlLimpo.');
      partes.add('Acesso em: ${_dataAtualFormatada()}.');
    }

    return partes.join(' ');
  }

  /// Formatação simplificada do nome para APA.
  ///
  /// Se o nome contiver apenas uma palavra, mantém-no.
  /// Se estiver no formato "Nome Sobrenome", converte para
  /// "Sobrenome, N.".
  String _formatarAutorAPA(String autor) {
    final nome = autor.trim();

    if (nome.isEmpty || nome == 'Autor não identificado') {
      return nome;
    }

    if (nome.contains(',')) {
      return nome;
    }

    final partes = nome
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.length == 1) {
      return partes.first;
    }

    final sobrenome = partes.last;
    final nomes = partes.sublist(0, partes.length - 1);

    final iniciais = nomes
        .map((parte) => '${parte[0].toUpperCase()}.')
        .join(' ');

    return '$sobrenome, $iniciais';
  }

  /// Formatação simplificada do nome para ABNT e ISO 690.
  String _formatarAutorABNT(String autor) {
    final nome = autor.trim();

    if (nome.isEmpty || nome == 'Autor não identificado') {
      return nome.toUpperCase();
    }

    if (nome.contains(',')) {
      final partes = nome.split(',');

      if (partes.length >= 2) {
        return '${partes.first.trim().toUpperCase()},'
            '${partes.sublist(1).join(',').trim()}';
      }
    }

    final partes = nome
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.length == 1) {
      return partes.first.toUpperCase();
    }

    final sobrenome = partes.removeLast().toUpperCase();

    return '$sobrenome, ${partes.join(' ')}';
  }

  /// Formatação simplificada do nome para Vancouver.
  String _formatarAutorVancouver(String autor) {
    final nome = autor.trim();

    if (nome.isEmpty || nome == 'Autor não identificado') {
      return nome;
    }

    if (nome.contains(',')) {
      return nome;
    }

    final partes = nome
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.length == 1) {
      return partes.first;
    }

    final sobrenome = partes.last;
    final iniciais = partes
        .sublist(0, partes.length - 1)
        .map((parte) => parte[0].toUpperCase())
        .join();

    return '$sobrenome $iniciais';
  }

  /// Formatação simplificada do nome para IEEE.
  String _formatarAutorIEEE(String autor) {
    final nome = autor.trim();

    if (nome.isEmpty || nome == 'Autor não identificado') {
      return nome;
    }

    if (nome.contains(',')) {
      return nome;
    }

    final partes = nome
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.length == 1) {
      return partes.first;
    }

    final sobrenome = partes.last;
    final nomes = partes.sublist(0, partes.length - 1);

    final iniciais = nomes
        .map((parte) => '${parte[0].toUpperCase()}.')
        .join(' ');

    return '$iniciais $sobrenome';
  }

  String _formatarTitulo(String titulo) {
    final texto = titulo.trim();

    if (texto.isEmpty) {
      return 'Título não identificado';
    }

    if (texto.endsWith('.') ||
        texto.endsWith('?') ||
        texto.endsWith('!')) {
      return texto;
    }

    return '$texto.';
  }

  String _dataAtualFormatada() {
    final agora = DateTime.now();

    const meses = [
      'jan.',
      'fev.',
      'mar.',
      'abr.',
      'maio',
      'jun.',
      'jul.',
      'ago.',
      'set.',
      'out.',
      'nov.',
      'dez.',
    ];

    return '${agora.day} ${meses[agora.month - 1]} ${agora.year}';
  }

  /// Regista uma referência bibliográfica associada a uma obra.
  ///
  /// Exige que o utilizador esteja autenticado.
  Future<CitacaoObra> registarCitacao({
    required String obraId,
    required String textoCitacao,
    String? tipoCitacao,
    String? urlCitacao,
  }) async {
    final utilizador = _supabase.auth.currentUser;

    if (utilizador == null) {
      throw Exception(
        'Inicia sessão para registar uma citação.',
      );
    }

    final idObra = obraId.trim();
    final texto = textoCitacao.trim();
    final tipo = tipoCitacao?.trim();
    final url = urlCitacao?.trim();

    if (idObra.isEmpty) {
      throw Exception(
        'O identificador da obra é obrigatório.',
      );
    }

    if (texto.isEmpty) {
      throw Exception(
        'O texto da citação é obrigatório.',
      );
    }

    final dados = <String, dynamic>{
      'obra_id': idObra,
      'user_id': utilizador.id,
      'texto_citacao': texto,
      'data_criacao': DateTime.now().toUtc().toIso8601String(),
      'tipo_citacao':
      tipo == null || tipo.isEmpty ? null : tipo,
      'url_citacao':
      url == null || url.isEmpty ? null : url,
    };

    final resposta = await _supabase
        .from(_tabela)
        .insert(dados)
        .select()
        .single();

    return CitacaoObra.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  /// Consulta todas as referências de uma obra.
  Future<List<CitacaoObra>> obterCitacoes(
      String obraId,
      ) async {
    final idObra = obraId.trim();

    if (idObra.isEmpty) {
      return <CitacaoObra>[];
    }

    final resposta = await _supabase
        .from(_tabela)
        .select()
        .eq('obra_id', idObra)
        .order('data_criacao', ascending: false);

    return (resposta as List)
        .map(
          (item) => CitacaoObra.fromMap(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }

  /// Conta os registos associados a uma obra.
  Future<int> contarCitacoes(String obraId) async {
    final idObra = obraId.trim();

    if (idObra.isEmpty) {
      return 0;
    }

    final resposta = await _supabase
        .from(_tabela)
        .select('id')
        .eq('obra_id', idObra);

    return (resposta as List).length;
  }

  /// Consulta as referências registadas pelo utilizador autenticado.
  Future<List<CitacaoObra>> obterMinhasCitacoes() async {
    final utilizador = _supabase.auth.currentUser;

    if (utilizador == null) {
      throw Exception(
        'Inicia sessão para consultar as tuas citações.',
      );
    }

    final resposta = await _supabase
        .from(_tabela)
        .select()
        .eq('user_id', utilizador.id)
        .order('data_criacao', ascending: false);

    return (resposta as List)
        .map(
          (item) => CitacaoObra.fromMap(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .toList();
  }
}

