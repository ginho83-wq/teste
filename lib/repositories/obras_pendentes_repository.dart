import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';

class ObrasPendentesRepository {
  ObrasPendentesRepository._();

  static final ObrasPendentesRepository instancia =
  ObrasPendentesRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _campos = '''
    id,
    titulo,
    descricao,
    autor,
    categoria,
    url_documento,
    ano_obra,
    data_publicacao,
    user_id,
    created_at,
    updated_at
  ''';

  Future<List<ObraPendente>> carregarTodas() async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .order('data_publicacao', ascending: false);

    return (resposta as List)
        .map(
          (item) => ObraPendente.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<ObraPendente?> carregarPorId(String id) async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq('id', id)
        .maybeSingle();

    if (resposta == null) {
      return null;
    }

    return ObraPendente.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  Future<List<ObraPendente>> carregarDoUsuario(
      String userId,
      ) async {
    final resposta = await _supabase
        .from('obras_pendentes')
        .select(_campos)
        .eq('user_id', userId)
        .order('data_publicacao', ascending: false);

    return (resposta as List)
        .map(
          (item) => ObraPendente.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  Future<ObraPendente> inserir(
      ObraPendente obra,
      ) async {
    final dados = obra.toMap();

    dados.remove('id');
    dados.remove('created_at');
    dados.remove('updated_at');

    final resposta = await _supabase
        .from('obras_pendentes')
        .insert(dados)
        .select(_campos)
        .single();

    return ObraPendente.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  Future<Obra> aprovar(String id) async {
    final pendente = await carregarPorId(id);

    if (pendente == null) {
      throw Exception('Obra pendente não encontrada.');
    }

    if (pendente.urlDocumento == null ||
        pendente.urlDocumento!.trim().isEmpty) {
      throw Exception(
        'O caminho do arquivo da obra pendente não foi encontrado.',
      );
    }

    final caminhoArquivo = pendente.urlDocumento!;

    final Uint8List arquivo = await _supabase.storage
        .from('obras_pendentes')
        .download(caminhoArquivo);

    await _supabase.storage
        .from('obras')
        .uploadBinary(
      caminhoArquivo,
      arquivo,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'application/pdf',
      ),
    );

    final urlPublica = _supabase.storage
        .from('obras')
        .getPublicUrl(caminhoArquivo);

    final dadosObra = <String, dynamic>{
      'titulo': pendente.titulo,
      'descricao': pendente.descricao,
      'autor': pendente.autor,
      'categoria': pendente.categoria,
      'url_documento': urlPublica,
      'ano_obra': pendente.anoObra,
      'data_publicacao':
      pendente.dataPublicacao?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'user_id': pendente.userId,
    };

    final resposta = await _supabase
        .from('obras')
        .insert(dadosObra)
        .select(_campos)
        .single();

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq('id', id);

    try {
      await _supabase.storage
          .from('obras_pendentes')
          .remove([caminhoArquivo]);
    } catch (_) {
      // A publicação já foi concluída.
      // A remoção do arquivo pendente não deve desfazer a aprovação.
    }

    return Obra.fromMap(
      Map<String, dynamic>.from(resposta),
    );
  }

  Future<void> rejeitar(String id) async {
    final pendente = await carregarPorId(id);

    if (pendente == null) {
      throw Exception('Obra pendente não encontrada.');
    }

    await _supabase
        .from('obras_pendentes')
        .delete()
        .eq('id', id);

    if (pendente.urlDocumento != null &&
        pendente.urlDocumento!.trim().isNotEmpty) {
      try {
        await _supabase.storage
            .from('obras_pendentes')
            .remove([pendente.urlDocumento!]);
      } catch (_) {
        // O registro já foi removido.
      }
    }
  }

  Future<void> excluir(String id) async {
    await rejeitar(id);
  }
}
