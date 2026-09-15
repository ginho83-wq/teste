import 'package:flutter/material.dart';

class Paginacao extends StatelessWidget {
  final int paginaAtual;
  final int totalPaginas;
  final ValueChanged<int> onPaginaChanged;

  const Paginacao({
    super.key,
    required this.paginaAtual,
    required this.totalPaginas,
    required this.onPaginaChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPaginas <= 1) {
      return const SizedBox.shrink();
    }

    final List<Widget> botoes = [];

    // Anterior
    botoes.add(
      _BotaoTexto(
        texto: 'Anterior',
        habilitado: paginaAtual > 1,
        onTap: paginaAtual > 1
            ? () => onPaginaChanged(paginaAtual - 1)
            : null,
      ),
    );

    // Calcula os números que serão exibidos.
    final Set<int> paginas = {};

    paginas.add(1);
    paginas.add(totalPaginas);

    for (int i = paginaAtual - 2; i <= paginaAtual + 2; i++) {
      if (i >= 1 && i <= totalPaginas) {
        paginas.add(i);
      }
    }

    final listaPaginas = paginas.toList()..sort();

    int? paginaAnterior;

    for (final pagina in listaPaginas) {
      // Adiciona "..." quando houver páginas ocultas.
      if (paginaAnterior != null && pagina - paginaAnterior > 1) {
        botoes.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 28,
              height: 40,
              child: Center(
                child: Text(
                  '...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      botoes.add(
        _BotaoPagina(
          pagina: pagina,
          selecionada: pagina == paginaAtual,
          onTap: () => onPaginaChanged(pagina),
        ),
      );

      paginaAnterior = pagina;
    }

    // Próximo
    botoes.add(
      _BotaoTexto(
        texto: 'Próximo',
        habilitado: paginaAtual < totalPaginas,
        onTap: paginaAtual < totalPaginas
            ? () => onPaginaChanged(paginaAtual + 1)
            : null,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(
        top: 28,
        bottom: 10,
      ),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          runSpacing: 4,
          children: botoes,
        ),
      ),
    );
  }
}

class _BotaoPagina extends StatelessWidget {
  final int pagina;
  final bool selecionada;
  final VoidCallback onTap;

  const _BotaoPagina({
    required this.pagina,
    required this.selecionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: selecionada
            ? Colors.black
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Center(
            child: Text(
              '$pagina',
              style: TextStyle(
                fontSize: 14,
                fontWeight: selecionada
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: selecionada
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoTexto extends StatelessWidget {
  final String texto;
  final bool habilitado;
  final VoidCallback? onTap;

  const _BotaoTexto({
    required this.texto,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: habilitado ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: Center(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 14,
                  color: habilitado
                      ? Colors.black87
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

