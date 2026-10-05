import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra_imagem.dart';

class ObrasImagensRepository {
  ObrasImagensRepository._();

  static final ObrasImagensRepository instancia =
  ObrasImagensRepository._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // INSERIR IMAGEM
  // ============================================================

  Future<ObraImagem> inserir(
      ObraImagem imagem,
      ) async {
    final dados = imagem.toMap();

    dados.remove('id');

    final resposta = await _supabase
        .from('teste_imagens')
        .insert(dados)
        .select(
      'id, obra_id, url_imagem, legenda, fonte, posicao, ordem',
    )
        .single();

    return ObraImagem.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  // ============================================================
  // CARREGAR IMAGENS DE UMA OBRA
  // ============================================================

  Future<List<ObraImagem>> carregarPorObra(
      String obraId,
      ) async {
    if (obraId.trim().isEmpty) {
      return [];
    }

    final resposta = await _supabase
        .from('teste_imagens')
        .select(
      'id, obra_id, url_imagem, legenda, fonte, posicao, ordem',
    )
        .eq('obra_id', obraId.trim())
        .order('ordem', ascending: true);

    return (resposta as List)
        .map(
          (item) => ObraImagem.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  // ============================================================
  // CARREGAR UMA IMAGEM PELO ID
  // ============================================================

  Future<ObraImagem?> carregarPorId(
      String id,
      ) async {
    if (id.trim().isEmpty) {
      return null;
    }

    final resposta = await _supabase
        .from('teste_imagens')
        .select(
      'id, obra_id, url_imagem, legenda, fonte, posicao, ordem',
    )
        .eq('id', id.trim())
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return ObraImagem.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  // ============================================================
  // ATUALIZAR IMAGEM
  // ============================================================

  Future<ObraImagem> atualizar(
      ObraImagem imagem,
      ) async {
    if (imagem.id == null ||
        imagem.id!.trim().isEmpty) {
      throw Exception(
        'Não é possível atualizar uma imagem sem ID.',
      );
    }

    final dados = imagem.toMap();

    dados.remove('id');
    dados.remove('obra_id');

    final resposta = await _supabase
        .from('teste_imagens')
        .update(dados)
        .eq('id', imagem.id!.trim())
        .select(
      'id, obra_id, url_imagem, legenda, fonte, posicao, ordem',
    )
        .single();

    return ObraImagem.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  // ============================================================
  // ELIMINAR IMAGEM
  // ============================================================

  Future<void> eliminar(
      String id,
      ) async {
    if (id.trim().isEmpty) {
      return;
    }

    await _supabase
        .from('teste_imagens')
        .delete()
        .eq('id', id.trim());
  }

  // ============================================================
  // ELIMINAR TODAS AS IMAGENS DE UMA OBRA
  // ============================================================

  Future<void> eliminarPorObra(
      String obraId,
      ) async {
    if (obraId.trim().isEmpty) {
      return;
    }

    await _supabase
        .from('teste_imagens')
        .delete()
        .eq('obra_id', obraId.trim());
  }
}
