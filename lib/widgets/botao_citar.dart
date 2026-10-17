import 'package:flutter/material.dart';
import 'dialogo_citacao.dart';
class BotaoCitar extends StatelessWidget { final String autor; final String titulo; final String? ano; final int? pagina; final String? trecho; final String? url;
const BotaoCitar({ super.key, required this.autor, required this.titulo, this.ano, this.pagina, this.trecho, this.url, });
@override Widget build(BuildContext context) { return OutlinedButton.icon( onPressed: () { DialogoCitacao.mostrar( context, autor: autor, titulo: titulo, ano: ano, pagina: pagina, trecho: trecho, url: url, ); }, icon: const Icon(Icons.format_quote), label: const Text('Citar'), ); } }
