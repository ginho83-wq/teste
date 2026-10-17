import 'package:flutter/material.dart';
import 'dialogo_citacao.dart';
class SelecaoCitacao extends StatelessWidget { final String texto; final String autor; final String titulo; final String? ano; final int? pagina; final String? url;
const SelecaoCitacao({ super.key, required this.texto, required this.autor, required this.titulo, this.ano, this.pagina, this.url, });
@override Widget build(BuildContext context) { return SelectableText( texto, textAlign: TextAlign.justify, style: const TextStyle( fontSize: 16, height: 1.6, ), contextMenuBuilder: (context, editableTextState) { final itens = [ ...editableTextState.contextMenuButtonItems, ContextMenuButtonItem( label: 'Citar', onPressed: () { final selecao = editableTextState.textEditingValue.selection;
final inicio = selecao.start;
final fim = selecao.end;

editableTextState.hideToolbar();

if (!selecao.isValid ||
    selecao.isCollapsed ||
    inicio < 0 ||
    fim > texto.length ||
    inicio >= fim) {
  return;
}

final trecho = texto.substring(inicio, fim).trim();

if (trecho.isEmpty) return;

DialogoCitacao.mostrar(
  context,
  autor: autor,
  titulo: titulo,
  ano: ano,
  pagina: pagina,
  trecho: trecho,
  url: url,
);
},
),
];

return AdaptiveTextSelectionToolbar.buttonItems(
  anchors: editableTextState.contextMenuAnchors,
  buttonItems: itens,
);
},
);
} }

