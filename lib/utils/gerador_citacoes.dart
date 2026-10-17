class GeradorCitacoes { GeradorCitacoes._();
static const List estilos = [ 'APA 7', 'ABNT', 'Vancouver', 'IEEE', 'ISO 690', ];
static const List tipos = [ 'Referência bibliográfica', 'Citação direta', 'Citação indireta', ];
static String _valor( String? valor, { String padrao = 's.d.', }) { final resultado = (valor ?? '').trim(); return resultado.isEmpty ? padrao : resultado; }
static String _limparAutor(String autor) { final resultado = autor.trim().replaceAll( RegExp(r'\s+'), ' ', );
return resultado.isEmpty
    ? 'Autor desconhecido'
    : resultado;
}
static List _nomesAutor(String autor) { final nome = _limparAutor(autor);
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
static String _primeiroNome(String autor) { final nomes = _nomesAutor(autor);
if (nomes.isEmpty) {
  return 'Autor desconhecido';
}

return nomes.first;
}
static String _sobrenome(String autor) { final nomes = _nomesAutor(autor);
if (nomes.isEmpty) {
  return 'Autor desconhecido';
}

return nomes.last;
}
static String _iniciais(String nome) { return nome .trim() .split(RegExp(r'\s+')) .where((parte) => parte.isNotEmpty) .map((parte) => '${parte[0].toUpperCase()}.') .join(' '); }
static String _autorFormatado( String autor, String estilo, ) { final nomes = _nomesAutor(autor);
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

    return '$sobrenome ${_iniciais(primeiro).replaceAll(' ', '')}';

  case 'IEEE':
    if (nomes.length == 1) return sobrenome;

    return '${_iniciais(primeiro)} $sobrenome';

  default:
    return '$primeiro $sobrenome';
}
}
static String _autorParaCitacao( String autor, String estilo, ) { final sobrenome = _sobrenome(autor);
switch (estilo) {
  case 'ABNT':
  case 'ISO 690':
    return sobrenome.toUpperCase();

  default:
    return sobrenome;
}
}
static String gerar({ required String estilo, required String tipo, required String titulo, required String autor, String? ano, String? trecho, int? pagina, String? url, }) { final estiloSelecionado = estilos.contains(estilo) ? estilo : 'APA 7';
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
      return 'Selecione ou introduza o trecho que pretende citar.';
    }

    final paginaTexto = pagina != null
        ? ', p. $pagina'
        : '';

    switch (estiloSelecionado) {
      case 'IEEE':
        return '“$texto” [$autorCitacao, $anoFinal$paginaTexto].';

      case 'Vancouver':
        return '“$texto” ($autorCitacao, $anoFinal$paginaTexto).';

      default:
        return '“$texto” ($autorCitacao, $anoFinal$paginaTexto).';
    }

  case 'Citação indireta':
    switch (estiloSelecionado) {
      case 'IEEE':
        return 'Segundo $autorCitacao [$anoFinal], $tituloFinal.';

      default:
        return 'Segundo $autorCitacao ($anoFinal), $tituloFinal.';
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
static String gerarReferencia({ required String estilo, required String titulo, required String autor, String? ano, String? url, }) { final estiloSelecionado = estilos.contains(estilo) ? estilo : 'APA 7';
final tituloFinal = _valor(
  titulo,
  padrao: 'Título não informado',
);

final anoFinal = _valor(ano);

final autorFinal = _autorFormatado(
  autor,
  estiloSelecionado,
);

final urlFinal = (url ?? '').trim();

switch (estiloSelecionado) {
  case 'APA 7':
    return '$autorFinal ($anoFinal). $tituloFinal.'
        '${urlFinal.isNotEmpty ? ' $urlFinal' : ''}';

  case 'ABNT':
    return '$autorFinal. $tituloFinal. $anoFinal.'
        '${urlFinal.isNotEmpty ? ' Disponível em: $urlFinal.' : ''}';

  case 'Vancouver':
    return '$autorFinal. $tituloFinal. $anoFinal.'
        '${urlFinal.isNotEmpty ? ' Disponível em: $urlFinal.' : ''}';

  case 'IEEE':
    return '$autorFinal, "$tituloFinal," $anoFinal.'
        '${urlFinal.isNotEmpty ? ' [Online]. Disponível: $urlFinal.' : ''}';

  case 'ISO 690':
    return '$autorFinal. $tituloFinal. $anoFinal.'
        '${urlFinal.isNotEmpty ? ' Disponível em: $urlFinal.' : ''}';

  default:
    return '$autorFinal ($anoFinal). $tituloFinal.';
}
} }

