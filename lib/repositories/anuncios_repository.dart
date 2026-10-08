import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anuncio.dart';

class AnunciosRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Anuncio>> carregarAnuncios({
    String? tipo,
    String posicao = 'lateral',
  }) async {
    try {
      print('----------------------------------------');
      print('CARREGANDO ANÚNCIOS');
      print('Tipo: $tipo');
      print('Posição: $posicao');

      var query = _supabase
          .from('anuncios')
          .select()
          .eq('ativo', true)
          .eq('posicao', posicao);

      if (tipo != null && tipo.trim().isNotEmpty) {
        query = query.eq('tipo', tipo.trim());
      }

      final resposta = await query.order(
        'ordem',
        ascending: true,
      );

      print('RESPOSTA DO SUPABASE: $resposta');

      final anuncios = (resposta as List)
          .map(
            (item) => Anuncio.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .where(
            (anuncio) => anuncio.estaDisponivel,
      )
          .toList();

      print('ANÚNCIOS VÁLIDOS: ${anuncios.length}');

      for (final anuncio in anuncios) {
        print(
          'Anúncio: ${anuncio.titulo} | '
              'tipo=${anuncio.tipo} | '
              'posição=${anuncio.posicao} | '
              'ativo=${anuncio.ativo}',
        );
      }

      print('----------------------------------------');

      return anuncios;
    } catch (e, stackTrace) {
      print('========================================');
      print('ERRO AO CARREGAR ANÚNCIOS');
      print('ERRO: $e');
      print('STACKTRACE:');
      print(stackTrace);
      print('========================================');

      rethrow;
    }
  }

  Future<List<Anuncio>> carregarVideos() async {
    return carregarAnuncios(
      tipo: 'video',
      posicao: 'lateral',
    );
  }

  Future<List<Anuncio>> carregarAnunciosFixos() async {
    return carregarAnuncios(
      tipo: 'fixo',
      posicao: 'lateral',
    );
  }

  Future<Anuncio?> carregarVideoPrincipal() async {
    final anuncios = await carregarVideos();

    if (anuncios.isEmpty) {
      print('NENHUM VÍDEO ENCONTRADO.');
      return null;
    }

    print(
      'VÍDEO PRINCIPAL: ${anuncios.first.titulo}',
    );

    return anuncios.first;
  }

  Future<Anuncio?> carregarAnuncioFixoPrincipal() async {
    final anuncios = await carregarAnunciosFixos();

    if (anuncios.isEmpty) {
      print('NENHUM ANÚNCIO FIXO ENCONTRADO.');
      return null;
    }

    print(
      'ANÚNCIO FIXO PRINCIPAL: ${anuncios.first.titulo}',
    );

    return anuncios.first;
  }
}
