class GeradorCitacoes {
  GeradorCitacoes._();

  static const List<String> estilos = [
    'APA 7',
    'ABNT',
    'Vancouver',
    'IEEE',
    'ISO 690',
  ];

  static const List<String> tipos = [
    'Referência bibliográfica',
    'Citação direta',
    'Citação indireta',
  ];

  static String _valor(
      String? valor, {
        String padrao = 's.d.',
      }) {
    final resultado = (valor ?? '').trim();
    return resultado.isEmpty ? padrao : resultado;
  }

  static String _limparAutor(String autor) {
    final resultado = autor.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return resultado.isEmpty
        ? 'Autor desconhecido'
        : resultado;
  }

  static List<String> _nomesAutor(String autor) {
    final nome = _limparAutor(autor);

    if (nome == 'Autor desconhecido') {
      return [];
    }

    if (nome.contains(',')) {
      final partes = nome.split(',');
      final sobrenome = partes.first.trim();
      final restantes = partes.skip(1).join(' ').trim();

      if (sobrenome.isNotEmpty && restantes.isNotEmpty) {
        return [restantes, sobrenome];
      }
    }

    return nome
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();
  }

  static String _primeiroNome(String autor) {
    final nomes = _nomesAutor(autor);

    if (nomes.isEmpty) {
      return 'Autor desconhecido';
    }

    return nomes.first;
  }

  static String _sobrenome(String autor) {
    final nomes = _nomesAutor(autor);

    if (nomes.isEmpty) {
      return 'Autor desconhecido';
    }

    return nomes.last;
  }

  static String _iniciais(String nome) {
    return nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .map((parte) => '${parte[0].toUpperCase()}.')
        .join(' ');
  }

  static String _autorFormatado(
      String autor,
      String estilo,
      ) {
    final nomes = _nomesAutor(autor);

    if (nomes.isEmpty) {
      return 'Autor desconhecido';
    }

    final primeiro = nomes.first;
    final sobrenome = nomes.last;

    switch (estilo) {
      case 'APA 7':
        if (nomes.length == 1) return sobrenome;

        return '$sobrenome, ${_iniciais(primeiro)}';

      case 'ABNT':
      case 'ISO 690':
        if (nomes.length == 1) {
          return sobrenome.toUpperCase();
        }

        return '${sobrenome.toUpperCase()}, $primeiro';

      case 'Vancouver':
        if (nomes.length == 1) return sobrenome;

        return '$sobrenome '
            '${_iniciais(primeiro).replaceAll(' ', '')}';

      case 'IEEE':
        if (nomes.length == 1) return sobrenome;

        return '${_iniciais(primeiro)} $sobrenome';

      default:
        return '$primeiro $sobrenome';
    }
  }

  static String _autorParaCitacao(
      String autor,
      String estilo,
      ) {
    final sobrenome = _sobrenome(autor);

    switch (estilo) {
      case 'ABNT':
      case 'ISO 690':
        return sobrenome.toUpperCase();

      default:
        return sobrenome;
    }
  }

  /// Normaliza o URL para a referência bibliográfica.
  ///
  /// Exemplo:
  /// http://localhost:3000/obra/UUID?parametro=1
  /// Resultado: http://localhost:3000/
  ///
  /// Exemplo:
  /// https://exemplo.com/teste/obra/UUID
  /// Resultado: https://exemplo.com/teste/
  static String _urlReferencia(String? url) {
    final valor = (url ?? '').trim();

    if (valor.isEmpty) return '';

    final uri = Uri.tryParse(valor);

    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      return valor;
    }

    final segmentos = List<String>.from(uri.pathSegments);

    final indiceObra = segmentos.indexWhere(
          (segmento) => segmento.toLowerCase() == 'obra',
    );

    final caminho = indiceObra >= 0
        ? segmentos.take(indiceObra).toList()
        : segmentos;

    return uri.replace(
      path: caminho.isEmpty
          ? '/'
          : '/${caminho.join('/')}/',
      query: null,
      fragment: null,
    ).toString();
  }

  /// Devolve o nome do mês em português.
  static String _nomeMes(int mes) {
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    return meses[mes - 1];
  }

  /// Formata a data de acesso.
  static String _dataAcessoFormatada() {
    final data = DateTime.now();

    return '${data.day.toString().padLeft(2, '0')} de '
        '${_nomeMes(data.month)} de '
        '${data.year}';
  }

  /// Gera a citação conforme a norma e o tipo selecionados.
  ///
  /// Na citação indireta, apresenta o autor e o ano
  /// antes do texto parafraseado.
  ///
  /// Na citação direta, acrescenta a página quando disponível.
  static String gerar({
    required String estilo,
    required String tipo,
    required String titulo,
    required String autor,
    String? ano,
    String? trecho,
    int? pagina,
    String? url,
  }) {
    final estiloSelecionado = estilos.contains(estilo)
        ? estilo
        : 'APA 7';

    final tituloFinal = _valor(
      titulo,
      padrao: 'Título não informado',
    );

    final anoFinal = _valor(ano);

    final autorCitacao = _autorParaCitacao(
      autor,
      estiloSelecionado,
    );

    switch (tipo) {
      case 'Citação direta':
        final texto = (trecho ?? '').trim();

        if (texto.isEmpty) {
          return 'Selecione ou introduza o trecho que '
              'pretende citar.';
        }

        final paginaTexto =
        pagina != null && pagina > 0
            ? ', p. $pagina'
            : '';

        switch (estiloSelecionado) {
          case 'IEEE':
            return '“$texto” '
                '[$autorCitacao, $anoFinal$paginaTexto].';

          case 'Vancouver':
            return '“$texto” '
                '($autorCitacao, $anoFinal$paginaTexto).';

          default:
            return '“$texto” '
                '($autorCitacao, $anoFinal$paginaTexto).';
        }

      case 'Citação indireta':
        final texto = (trecho ?? '').trim();

        if (texto.isEmpty) {
          return 'Selecione um trecho e escreva a paráfrase '
              'com palavras próprias antes de gerar a citação.';
        }

        switch (estiloSelecionado) {
          case 'IEEE':
            return '[$autorCitacao, $anoFinal]. $texto';

          case 'ABNT':
          case 'ISO 690':
          case 'APA 7':
          case 'Vancouver':
          default:
            return '($autorCitacao, $anoFinal). $texto';
        }

      case 'Referência bibliográfica':
      default:
        return gerarReferencia(
          estilo: estiloSelecionado,
          titulo: tituloFinal,
          autor: autor,
          ano: anoFinal,
          url: url,
        );
    }
  }

  /// Gera a referência bibliográfica com URL normalizado
  /// e data de acesso.
  static String gerarReferencia({
    required String estilo,
    required String titulo,
    required String autor,
    String? ano,
    String? url,
  }) {
    final estiloSelecionado = estilos.contains(estilo)
        ? estilo
        : 'APA 7';

    final tituloFinal = _valor(
      titulo,
      padrao: 'Título não informado',
    );

    final anoFinal = _valor(ano);

    final autorFinal = _autorFormatado(
      autor,
      estiloSelecionado,
    );

    final urlFinal = _urlReferencia(url);

    final dataAcesso = _dataAcessoFormatada();

    switch (estiloSelecionado) {
      case 'APA 7':
        return '$autorFinal ($anoFinal). $tituloFinal.'
            '${urlFinal.isNotEmpty ? ' $urlFinal. '
            'Acedido em $dataAcesso.' : ''}';

      case 'ABNT':
        return '$autorFinal. $tituloFinal. $anoFinal.'
            '${urlFinal.isNotEmpty ? ' Disponível em: $urlFinal. '
            'Acesso em: $dataAcesso.' : ''}';

      case 'Vancouver':
        return '$autorFinal. $tituloFinal. $anoFinal.'
            '${urlFinal.isNotEmpty ? ' Disponível em: $urlFinal. '
            'Acesso em: $dataAcesso.' : ''}';

      case 'IEEE':
        return '$autorFinal, "$tituloFinal," $anoFinal.'
            '${urlFinal.isNotEmpty ? ' [Online]. Disponível: '
            '$urlFinal. [Acedido em: $dataAcesso].' : ''}';

      case 'ISO 690':
        return '$autorFinal. $tituloFinal. $anoFinal.'
            '${urlFinal.isNotEmpty ? ' Disponível em: $urlFinal. '
            'Acesso em: $dataAcesso.' : ''}';

      default:
        return '$autorFinal ($anoFinal). $tituloFinal.'
            '${urlFinal.isNotEmpty ? ' $urlFinal. '
            'Acedido em $dataAcesso.' : ''}';
    }
  }
}

