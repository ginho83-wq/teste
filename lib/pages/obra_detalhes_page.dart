import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/obra.dart';
import '../models/obra_imagem.dart';
import '../models/obra_secao.dart';
import '../repositories/obras_repository.dart';
import '../repositories/obras_imagens_repository.dart';
import '../repositories/obra_secoes_repository.dart';
import '../repositories/solicitacoes_remocao_repository.dart';
import '../services/auth_service.dart';
import '../services/historico_obras_service.dart';
import '../widgets/comentarios_section.dart';
import '../widgets/obra_lista_item.dart';

class ObraDetalhesPage extends StatefulWidget {
  final String id;

  const ObraDetalhesPage({
    super.key,
    required this.id,
  });

  @override
  State<ObraDetalhesPage> createState() =>
      _ObraDetalhesPageState();
}

class _ObraDetalhesPageState
    extends State<ObraDetalhesPage> {
  final ObrasRepository _repository =
      ObrasRepository.instancia;

  final ObrasImagensRepository _imagensRepository =
      ObrasImagensRepository.instancia;

  final ObraSecoesRepository _secoesRepository =
      ObraSecoesRepository.instancia;

  final HistoricoObrasService _historicoService =
      HistoricoObrasService.instancia;

  final SolicitacoesRemocaoRepository
  _solicitacoesRepository =
      SolicitacoesRemocaoRepository.instancia;

  final AuthService _authService =
      AuthService.instancia;

  Obra? _obra;

  List<ObraImagem> _imagens = [];

  List<ObraSecao> _secoes = [];

  // ============================================================
  // OBRAS RELACIONADAS
  // ============================================================

  List<Obra> _obrasRelacionadas = [];

  bool _carregandoRelacionadas = false;

  bool _carregando = true;
  bool _carregandoImagens = false;
  bool _carregandoSecoes = false;
  bool _carregandoSolicitacao = false;
  bool _enviandoSolicitacao = false;

  bool _estaAutenticado = false;
  bool _ehAdmin = false;

  Map<String, dynamic>? _solicitacaoPendente;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarObra();
  }

  // ============================================================
  // CARREGAR OBRA
  // ============================================================

  Future<void> _carregarObra() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
      _obrasRelacionadas = [];
    });

    try {
      final obra =
      await _repository.carregarPorId(widget.id);

      if (!mounted) return;

      if (obra == null) {
        setState(() {
          _carregando = false;
          _erro = 'Obra não encontrada.';
        });
        return;
      }

      setState(() {
        _obra = obra;
        _carregando = false;
      });

      await _carregarImagens(obra.id);

      await _carregarSecoes(obra.id);

      await _carregarObrasRelacionadas(obra);

      try {
        await _historicoService.registrarConsulta(
          obraId: obra.id,
        );
      } catch (e) {
        debugPrint(
          'OBRA DETALHES: erro ao registrar histórico: $e',
        );
      }

      await _carregarEstadoAutenticacao();

      await _carregarEstadoRemocao(obra.id);
    } catch (e) {
      debugPrint(
        'OBRA DETALHES: erro ao carregar obra: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro =
        'Não foi possível carregar esta obra.';
      });
    }
  }

  // ============================================================
  // CARREGAR IMAGENS
  // ============================================================

  Future<void> _carregarImagens(
      String obraId,
      ) async {
    if (!mounted) return;

    setState(() {
      _carregandoImagens = true;
    });

    try {
      final imagens =
      await _imagensRepository.carregarPorObra(
        obraId,
      );

      final imagensValidas = imagens
          .where(
            (imagem) =>
        imagem.urlImagem.trim().isNotEmpty,
      )
          .toList()
        ..sort(
              (a, b) => a.ordem.compareTo(b.ordem),
        );

      if (!mounted) return;

      setState(() {
        _imagens = imagensValidas;
        _carregandoImagens = false;
      });
    } catch (e) {
      debugPrint(
        'OBRA DETALHES: erro ao carregar imagens: $e',
      );

      if (!mounted) return;

      setState(() {
        _imagens = [];
        _carregandoImagens = false;
      });
    }
  }

  // ============================================================
  // CARREGAR SECÇÕES REAIS
  // ============================================================

  Future<void> _carregarSecoes(
      String obraId,
      ) async {
    if (!mounted) return;

    setState(() {
      _carregandoSecoes = true;
    });

    try {
      final secoes =
      await _secoesRepository.carregarPorObra(
        obraId,
      );

      if (!mounted) return;

      setState(() {
        _secoes = secoes;
        _carregandoSecoes = false;
      });
    } catch (e) {
      debugPrint(
        'OBRA DETALHES: erro ao carregar secções: $e',
      );

      if (!mounted) return;

      setState(() {
        _secoes = [];
        _carregandoSecoes = false;
      });
    }
  }

  // ============================================================
  // NORMALIZAR TEXTO
  // ============================================================

  String _normalizarTitulo(
      String texto,
      ) {
    var valor = texto.toLowerCase().trim();

    const substituicoes = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    substituicoes.forEach(
          (original, substituto) {
        valor = valor.replaceAll(
          original,
          substituto,
        );
      },
    );

    valor = valor.replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      ' ',
    );

    valor = valor.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return valor.trim();
  }

  // ============================================================
  // PALAVRAS IMPORTANTES
  // ============================================================

  Set<String> _palavrasImportantes(
      String titulo,
      ) {
    final normalizado =
    _normalizarTitulo(titulo);

    if (normalizado.isEmpty) {
      return {};
    }

    const palavrasIgnoradas = {
      'a',
      'as',
      'o',
      'os',
      'um',
      'uma',
      'uns',
      'umas',
      'de',
      'da',
      'das',
      'do',
      'dos',
      'em',
      'no',
      'na',
      'nos',
      'nas',
      'por',
      'para',
      'com',
      'sem',
      'sobre',
      'entre',
      'e',
      'ou',
      'que',
      'se',
      'ao',
      'aos',
      'à',
      'às',
      'como',
      'mais',
      'menos',
      'seu',
      'sua',
      'seus',
      'suas',
    };

    return normalizado
        .split(' ')
        .where(
          (palavra) =>
      palavra.length >= 3 &&
          !palavrasIgnoradas.contains(
            palavra,
          ),
    )
        .toSet();
  }

  // ============================================================
  // CALCULAR SEMELHANÇA ENTRE TÍTULOS
  // ============================================================

  int _pontuacaoTitulo(
      String tituloAtual,
      String tituloComparado,
      ) {
    final palavrasAtuais =
    _palavrasImportantes(tituloAtual);

    final palavrasComparadas =
    _palavrasImportantes(tituloComparado);

    if (palavrasAtuais.isEmpty ||
        palavrasComparadas.isEmpty) {
      return 0;
    }

    var pontuacao = 0;

    for (final palavra in palavrasAtuais) {
      if (palavrasComparadas.contains(palavra)) {
        pontuacao += 10;
      }
    }

    final palavrasEmComum =
    palavrasAtuais.intersection(
      palavrasComparadas,
    );

    if (palavrasEmComum.length >= 2) {
      pontuacao += 10;
    }

    if (palavrasEmComum.length >= 3) {
      pontuacao += 10;
    }

    final titulo1 =
    _normalizarTitulo(tituloAtual);

    final titulo2 =
    _normalizarTitulo(tituloComparado);

    if (titulo1.isNotEmpty &&
        titulo2.isNotEmpty) {
      if (titulo1.contains(titulo2) ||
          titulo2.contains(titulo1)) {
        pontuacao += 20;
      }
    }

    if (pontuacao > 50) {
      pontuacao = 50;
    }

    return pontuacao;
  }

  // ============================================================
  // CARREGAR OBRAS RELACIONADAS
  // ============================================================

  Future<void> _carregarObrasRelacionadas(
      Obra obra,
      ) async {
    if (!mounted) return;

    setState(() {
      _carregandoRelacionadas = true;
    });

    try {
      final todas =
      await _repository.carregarTodas();

      final obrasPorId = <String, Obra>{};

      for (final outra in todas) {
        final id = outra.id.trim();

        if (id.isEmpty) {
          continue;
        }

        if (id == obra.id.trim()) {
          continue;
        }

        obrasPorId[id] = outra;
      }

      final candidatos =
      <_ObraRelacionada>[];

      for (final outra in obrasPorId.values) {
        var pontuacao = 0;

        final pontuacaoTitulo =
        _pontuacaoTitulo(
          obra.titulo,
          outra.titulo,
        );

        pontuacao += pontuacaoTitulo;

        final categoriaAtual =
        _normalizarTitulo(
          obra.categoria,
        );

        final categoriaOutra =
        _normalizarTitulo(
          outra.categoria,
        );

        final mesmaCategoria =
            categoriaAtual.isNotEmpty &&
                categoriaOutra.isNotEmpty &&
                categoriaAtual ==
                    categoriaOutra;

        if (mesmaCategoria) {
          pontuacao += 20;
        }

        final autorAtual =
        _normalizarTitulo(
          obra.autor,
        );

        final autorOutro =
        _normalizarTitulo(
          outra.autor,
        );

        final mesmoAutor =
            autorAtual.isNotEmpty &&
                autorOutro.isNotEmpty &&
                autorAtual == autorOutro;

        if (mesmoAutor) {
          pontuacao += 20;
        }

        final anoAtual = obra.anoObra;
        final anoOutro = outra.anoObra;

        if (anoAtual != null &&
            anoOutro != null) {
          final diferenca =
          (anoAtual - anoOutro).abs();

          if (diferenca == 0) {
            pontuacao += 10;
          } else if (diferenca == 1) {
            pontuacao += 6;
          } else if (diferenca == 2) {
            pontuacao += 3;
          }
        }

        if (pontuacao < 20) {
          continue;
        }

        candidatos.add(
          _ObraRelacionada(
            obra: outra,
            pontuacao: pontuacao,
          ),
        );
      }

      candidatos.sort(
            (a, b) {
          final resultado =
          b.pontuacao.compareTo(
            a.pontuacao,
          );

          if (resultado != 0) {
            return resultado;
          }

          final dataA =
              a.obra.dataPublicacao;

          final dataB =
              b.obra.dataPublicacao;

          if (dataA != null &&
              dataB != null) {
            return dataB.compareTo(dataA);
          }

          if (dataA != null) {
            return -1;
          }

          if (dataB != null) {
            return 1;
          }

          return 0;
        },
      );

      final idsAdicionados =
      <String>{};

      final chavesAdicionadas =
      <String>{};

      final relacionadas = <Obra>[];

      for (final candidato in candidatos) {
        final obraRelacionada =
            candidato.obra;

        final id =
        obraRelacionada.id.trim();

        if (id.isEmpty) {
          continue;
        }

        if (idsAdicionados.contains(id)) {
          continue;
        }

        final chave = [
          _normalizarTitulo(
            obraRelacionada.titulo,
          ),
          _normalizarTitulo(
            obraRelacionada.autor,
          ),
          _normalizarTitulo(
            obraRelacionada.categoria,
          ),
          obraRelacionada.anoObra
              ?.toString() ??
              '',
        ].join('|');

        if (chavesAdicionadas.contains(
          chave,
        )) {
          continue;
        }

        idsAdicionados.add(id);
        chavesAdicionadas.add(chave);

        relacionadas.add(
          obraRelacionada,
        );

        if (relacionadas.length >= 5) {
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        _obrasRelacionadas =
            relacionadas;
        _carregandoRelacionadas = false;
      });
    } catch (e) {
      debugPrint(
        'OBRA DETALHES: erro ao carregar '
            'obras relacionadas: $e',
      );

      if (!mounted) return;

      setState(() {
        _obrasRelacionadas = [];
        _carregandoRelacionadas = false;
      });
    }
  }

  // ============================================================
  // AUTENTICAÇÃO
  // ============================================================

  Future<void>
  _carregarEstadoAutenticacao() async {
    try {
      final utilizador =
          _authService.usuarioAtual;

      final autenticado =
          utilizador != null;

      bool admin = false;

      if (autenticado) {
        try {
          admin =
          await _authService.ehAdmin();
        } catch (e) {
          debugPrint(
            'OBRA DETALHES: erro ao verificar '
                'admin: $e',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _estaAutenticado =
            autenticado;
        _ehAdmin = admin;
      });
    } catch (e) {
      debugPrint(
        'OBRA DETALHES: erro autenticação: $e',
      );
    }
  }

  // ============================================================
  // ESTADO DA SOLICITAÇÃO
  // ============================================================

  Future<void> _carregarEstadoRemocao(
      String obraId,
      ) async {
    if (!_estaAutenticado) return;

    if (!mounted) return;

    setState(() {
      _carregandoSolicitacao = true;
    });

    try {
      final solicitacao =
      await _solicitacoesRepository
          .obterSolicitacaoPendente(
        obraId,
      );

      if (!mounted) return;

      setState(() {
        _solicitacaoPendente =
            solicitacao;
        _carregandoSolicitacao = false;
      });
    } catch (e) {
      debugPrint(
        'OBRA DETALHES: erro ao carregar '
            'solicitação: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregandoSolicitacao = false;
      });
    }
  }

  // ============================================================
  // SOLICITAR REMOÇÃO
  // ============================================================

  Future<void> _solicitarRemocao() async {
    final obra = _obra;

    if (obra == null) return;

    if (!_estaAutenticado) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'É necessário iniciar sessão para '
                'solicitar a remoção.',
          ),
        ),
      );
      return;
    }

    if (_enviandoSolicitacao) return;

    final motivoController =
    TextEditingController();

    final motivo =
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Solicitar remoção',
          ),
          content: TextField(
            controller: motivoController,
            maxLines: 5,
            decoration:
            const InputDecoration(
              labelText: 'Motivo',
              hintText:
              'Explique o motivo da solicitação...',
              border:
              OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  motivoController.text
                      .trim(),
                );
              },
              child: const Text(
                'Enviar',
              ),
            ),
          ],
        );
      },
    );

    motivoController.dispose();

    if (motivo == null ||
        motivo.trim().isEmpty) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _enviandoSolicitacao = true;
    });

    try {
      await _solicitacoesRepository
          .criarSolicitacao(
        obraId: obra.id,
        motivo: motivo.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitação de remoção enviada.',
          ),
        ),
      );

      await _carregarEstadoRemocao(
        obra.id,
      );
    } catch (e) {
      debugPrint(
        'OBRA DETALHES: erro ao solicitar '
            'remoção: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível enviar a '
                'solicitação: $e',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _enviandoSolicitacao = false;
      });
    }
  }

  // ============================================================
  // CABEÇALHO
  // ============================================================

  Widget _buildCabecalho(
      Obra obra,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          obra.titulo,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (obra.autor
                .trim()
                .isNotEmpty)
              _buildChip(
                Icons.person_outline,
                obra.autor,
              ),
            if (obra.categoria
                .trim()
                .isNotEmpty)
              _buildChip(
                Icons.category_outlined,
                obra.categoria,
              ),
            if (obra.anoObra != null)
              _buildChip(
                Icons.calendar_today_outlined,
                obra.anoObra.toString(),
              ),
            if (obra.dataPublicacao != null)
              _buildChip(
                Icons.event_outlined,
                _formatarData(
                  obra.dataPublicacao!,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CHIP
  // ============================================================

  Widget _buildChip(
      IconData icon,
      String texto,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFDADCE0),
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF5F6368),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5F6368),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATA
  // ============================================================

  String _formatarData(
      DateTime data,
      ) {
    final dia =
    data.day.toString().padLeft(2, '0');

    final mes =
    data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // ============================================================
  // PUBLICIDADE
  // ============================================================

  Widget _buildPublicidade() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE0E0E0),
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Publicidade',
        style: TextStyle(
          color: Color(0xFF9AA0A6),
          fontSize: 13,
        ),
      ),
    );
  }

  // ============================================================
  // INFORMAÇÕES TÉCNICAS
  // ============================================================

  Widget _buildInformacoesTecnicas(
      Obra obra,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações técnicas',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 28,
          runSpacing: 16,
          children: [
            if (obra.numeroPaginas != null)
              _buildInfoTecnica(
                Icons.menu_book_outlined,
                'Páginas',
                obra.numeroPaginas.toString(),
              ),
            if (obra.tamanhoArquivoBytes != null)
              _buildInfoTecnica(
                Icons.storage_outlined,
                'Tamanho',
                _formatarTamanho(
                  obra.tamanhoArquivoBytes!,
                ),
              ),
            _buildInfoTecnica(
              Icons.picture_as_pdf_outlined,
              'Formato',
              'PDF',
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ITEM TÉCNICO
  // ============================================================

  Widget _buildInfoTecnica(
      IconData icon,
      String titulo,
      String valor,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF5F6368),
        ),
        const SizedBox(width: 8),
        Text(
          '$titulo: ',
          style: const TextStyle(
            color: Color(0xFF5F6368),
            fontSize: 14,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Color(0xFF202124),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TAMANHO
  // ============================================================

  String _formatarTamanho(
      int bytes,
      ) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================
  // BOTÕES DO DOCUMENTO
  // ============================================================

  Widget _buildBotoesDocumento(
      Obra obra,
      ) {
    final urlPdf =
    obra.urlDocumento.trim();

    if (urlPdf.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () async {
            final uri =
            Uri.tryParse(urlPdf);

            if (uri == null) return;

            await launchUrl(
              uri,
              webOnlyWindowName: '_blank',
            );
          },
          icon: const Icon(
            Icons.menu_book_outlined,
          ),
          label: const Text(
            'Ler PDF',
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final uri =
            Uri.tryParse(urlPdf);

            if (uri == null) return;

            await launchUrl(
              uri,
              webOnlyWindowName: '_blank',
            );
          },
          icon: const Icon(
            Icons.download_outlined,
          ),
          label: const Text(
            'Download PDF',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PARÁGRAFOS
  // ============================================================

  List<String> _obterParagrafos(
      String texto,
      ) {
    return texto
        .split(
      RegExp(r'\n\s*\n'),
    )
        .map(
          (p) => p.trim(),
    )
        .where(
          (p) => p.isNotEmpty,
    )
        .toList();
  }

  // ============================================================
  // CONTEÚDO DE SECÇÃO
  // ============================================================

  List<Widget> _buildConteudoSecao(
      String texto,
      ) {
    final paragrafos =
    _obterParagrafos(texto);

    if (paragrafos.isEmpty) {
      return [];
    }

    final widgets = <Widget>[];

    for (var i = 0;
    i < paragrafos.length;
    i++) {
      widgets.add(
        SelectableText(
          paragrafos[i],
          style: const TextStyle(
            fontSize: 16,
            height: 1.8,
            color: Color(0xFF3C4043),
          ),
        ),
      );

      if (i < paragrafos.length - 1) {
        widgets.add(
          const SizedBox(height: 18),
        );
      }
    }

    return widgets;
  }

  // ============================================================
  // IMAGEM INDIVIDUAL DA GALERIA
  // ============================================================

  Widget _buildImagemEditorial(
      ObraImagem imagem,
      int numeroFigura,
      double largura,
      ) {
    final legenda =
        imagem.legenda?.trim() ?? '';

    return SizedBox(
      width: largura,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
              borderRadius:
              BorderRadius.circular(6),
            ),
            clipBehavior:
            Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                imagem.urlImagem,
                fit: BoxFit.contain,
                loadingBuilder: (
                    context,
                    child,
                    loadingProgress,
                    ) {
                  if (loadingProgress ==
                      null) {
                    return child;
                  }

                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                },
                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return const Center(
                    child: Padding(
                      padding:
                      EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .broken_image_outlined,
                            color:
                            Color(0xFF9AA0A6),
                            size: 30,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Não foi possível '
                                'carregar esta imagem.',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              color:
                              Color(0xFF5F6368),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (legenda.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Figura $numeroFigura — $legenda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF5F6368),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // GALERIA DE IMAGENS
  //
  // REGRA:
  // - As imagens são opcionais.
  // - Se não houver imagens, não aparece galeria.
  // - As imagens aparecem depois de todo o conteúdo textual.
  // - Desktop largo: até 4 imagens por linha.
  // - Larguras intermédias: 3 ou 2 por linha.
  // - Telemóvel: 1 por linha.
  // ============================================================

  Widget _buildGaleriaImagensEditorial(
      double larguraDisponivel,
      ) {
    if (_imagens.isEmpty) {
      return const SizedBox.shrink();
    }

    var numeroColunas = 1;

    if (larguraDisponivel >= 760) {
      numeroColunas = 4;
    } else if (larguraDisponivel >= 560) {
      numeroColunas = 3;
    } else if (larguraDisponivel >= 360) {
      numeroColunas = 2;
    }

    const espacamento = 16.0;

    final larguraImagem =
        (larguraDisponivel -
            ((numeroColunas - 1) *
                espacamento)) /
            numeroColunas;

    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 32,
      ),
      child: Wrap(
        spacing: espacamento,
        runSpacing: 24,
        alignment: WrapAlignment.start,
        children: [
          for (var i = 0;
          i < _imagens.length;
          i++)
            _buildImagemEditorial(
              _imagens[i],
              i + 1,
              larguraImagem,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECÇÕES REAIS
  //
  // REGRA DAS IMAGENS:
  //
  // O número de parágrafos não interfere na posição das imagens.
  //
  // Pode existir:
  // - nenhum parágrafo;
  // - 1 parágrafo;
  // - 3 parágrafos;
  // - vários parágrafos.
  //
  // As imagens são opcionais e, quando existem, aparecem
  // depois de todo o conteúdo textual da obra.
  // ============================================================

  Widget _buildSecoesDaObra() {
    if (_carregandoSecoes) {
      return const Center(
        child: Padding(
          padding:
          EdgeInsets.symmetric(
            vertical: 30,
          ),
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    final widgets = <Widget>[];

    for (var indiceSecao = 0;
    indiceSecao < _secoes.length;
    indiceSecao++) {
      final secao =
      _secoes[indiceSecao];

      final titulo =
      secao.titulo.trim();

      final conteudo =
          secao.conteudo?.trim() ?? '';

      if (titulo.isEmpty &&
          conteudo.isEmpty) {
        continue;
      }

      widgets.add(
        Padding(
          padding:
          const EdgeInsets.only(
            bottom: 32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              if (titulo.isNotEmpty)
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize:
                    secao.nivel <= 1
                        ? 22
                        : 19,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    const Color(
                      0xFF202124,
                    ),
                    height: 1.3,
                  ),
                ),
              if (titulo.isNotEmpty &&
                  conteudo.isNotEmpty)
                const SizedBox(
                  height: 14,
                ),
              if (conteudo.isNotEmpty)
                ..._buildConteudoSecao(
                  conteudo,
                ),
            ],
          ),
        ),
      );
    }

    // Se não houver secções, mas existirem imagens,
    // mostra apenas a galeria.
    if (widgets.isEmpty) {
      if (_imagens.isEmpty) {
        return const SizedBox.shrink();
      }

      return LayoutBuilder(
        builder: (
            context,
            constraints,
            ) {
          return _buildGaleriaImagensEditorial(
            constraints.maxWidth,
          );
        },
      );
    }

    // Conteúdo textual primeiro.
    //
    // A galeria é opcional e fica sempre depois
    // de TODAS as secções/conteúdos.
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        return Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            ...widgets,

            if (_imagens.isNotEmpty)
              _buildGaleriaImagensEditorial(
                constraints.maxWidth,
              ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SEPARADOR
  // ============================================================

  Widget _buildSeparador() {
    return const Padding(
      padding:
      EdgeInsets.symmetric(
        vertical: 30,
      ),
      child: Divider(
        height: 1,
        color: Color(0xFFE8EAED),
      ),
    );
  }

  // ============================================================
  // REMOÇÃO
  // ============================================================

  Widget _buildSolicitacaoRemocao(
      Obra obra,
      ) {
    if (_ehAdmin) {
      return const SizedBox.shrink();
    }

    if (!_estaAutenticado) {
      return const SizedBox.shrink();
    }

    if (_carregandoSolicitacao) {
      return const SizedBox(
        height: 50,
        child: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    final existeSolicitacao =
        _solicitacaoPendente != null;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Remoção da obra',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          existeSolicitacao
              ? 'Já existe uma solicitação de remoção '
              'pendente para esta obra.'
              : 'Se identificar algum problema com '
              'esta publicação, pode solicitar a sua '
              'remoção para análise administrativa.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF5F6368),
          ),
        ),
        const SizedBox(height: 14),
        if (!existeSolicitacao)
          OutlinedButton.icon(
            onPressed:
            _enviandoSolicitacao
                ? null
                : _solicitarRemocao,
            icon:
            _enviandoSolicitacao
                ? const SizedBox(
              width: 16,
              height: 16,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.report_outlined,
            ),
            label: Text(
              _enviandoSolicitacao
                  ? 'A enviar...'
                  : 'Solicitar remoção',
            ),
          ),
      ],
    );
  }

  // ============================================================
  // OBRAS RELACIONADAS
  // ============================================================

  Widget _buildObrasRelacionadas() {
    if (_carregandoRelacionadas) {
      return const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Obras relacionadas',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF202124),
            ),
          ),
          SizedBox(height: 20),
          Center(
            child:
            CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_obrasRelacionadas.isEmpty) {
      return const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Obras relacionadas',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF202124),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Ainda não existem outras obras '
                'suficientemente relacionadas a esta publicação.',
            style: TextStyle(
              fontSize: 14,
              color:
              Color(0xFF5F6368),
            ),
          ),
        ],
      );
    }

    final mobile =
        MediaQuery.of(context)
            .size
            .width <
            600;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Obras relacionadas',
          style: TextStyle(
            fontSize: 21,
            fontWeight:
            FontWeight.w700,
            color:
            Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 8),
        ..._obrasRelacionadas.map(
              (obra) {
            return ObraListaItem(
              obra: obra,
              mobile: mobile,
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ObraDetalhesPage(
                          id: obra.id,
                        ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // CONTEÚDO PRINCIPAL
  // ============================================================

  Widget _buildConteudoPrincipal(
      Obra obra,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildCabecalho(obra),

        if (_secoes.isNotEmpty ||
            _imagens.isNotEmpty) ...[
          _buildSeparador(),
          _buildSecoesDaObra(),
        ],

        _buildSeparador(),

        _buildInformacoesTecnicas(
          obra,
        ),

        _buildSeparador(),

        _buildBotoesDocumento(
          obra,
        ),

        _buildSeparador(),

        _buildSolicitacaoRemocao(
          obra,
        ),

        _buildSeparador(),

        ComentariosSection(
          obraId: obra.id,
        ),

        _buildSeparador(),

        _buildObrasRelacionadas(),
      ],
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildEstadoErro() {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Obra Livre'),
      ),
      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color:
                Color(0xFF9AA0A6),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                _erro ??
                    'Ocorreu um erro.',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 16,
                  color:
                  Color(0xFF5F6368),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              FilledButton.icon(
                onPressed:
                _carregarObra,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_carregando) {
      return Scaffold(
        appBar: AppBar(
          title:
          const Text('Obra Livre'),
        ),
        body: const Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_erro != null) {
      return _buildEstadoErro();
    }

    final obra = _obra;

    if (obra == null) {
      return Scaffold(
        appBar: AppBar(
          title:
          const Text('Obra Livre'),
        ),
        body: const Center(
          child: Text(
            'Obra não encontrada.',
          ),
        ),
      );
    }

    return Title(
      title:
      '${obra.titulo} — Obra Livre',
      color:
      const Color(0xFF1A73E8),
      child: Scaffold(
        appBar: AppBar(
          title:
          const Text('Obra Livre'),
          backgroundColor:
          const Color(0xFFEAF4FF),
          elevation: 0,
        ),
        body: LayoutBuilder(
          builder: (
              context,
              constraints,
              ) {
            final desktop =
                constraints.maxWidth >=
                    1000;

            return SingleChildScrollView(
              padding:
              EdgeInsets.symmetric(
                horizontal:
                desktop ? 32 : 16,
                vertical: 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 1280,
                  ),
                  child: desktop
                      ? Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Expanded(
                        flex: 7,
                        child:
                        _buildConteudoPrincipal(
                          obra,
                        ),
                      ),
                      const SizedBox(
                        width: 28,
                      ),
                      SizedBox(
                        width: 300,
                        child:
                        _buildPublicidade(),
                      ),
                    ],
                  )
                      : Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      _buildConteudoPrincipal(
                        obra,
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      _buildPublicidade(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// MODELO INTERNO PARA CLASSIFICAR OBRAS RELACIONADAS
// ================================================================

class _ObraRelacionada {
  final Obra obra;
  final int pontuacao;

  const _ObraRelacionada({
    required this.obra,
    required this.pontuacao,
  });
}

