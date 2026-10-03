import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra_secao.dart';

class ObraSecoesRepository {
  ObraSecoesRepository._();

  static final ObraSecoesRepository instancia =
  ObraSecoesRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<List<ObraSecao>> carregarPorObra(
      String obraId,
      ) async {
    final resposta = await _supabase
        .from('teste_secoes')
        .select(
      'id, obra_id, titulo, conteudo, ordem, nivel',
    )
        .eq('obra_id', obraId)
        .order('ordem', ascending: true);

    return (resposta as List)
        .map(
          (item) => ObraSecao.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }
}

