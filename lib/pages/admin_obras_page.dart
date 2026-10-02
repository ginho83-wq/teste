import 'package:flutter/material.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../services/admin_service.dart';
import '../widgets/barra_pesquisa.dart';
import '../widgets/obra_lista_item.dart';
import '../widgets/paginacao.dart';
import 'admin_solicitacoes_remocao_page.dart';

class AdminObrasPage extends StatefulWidget {
  const AdminObrasPage({super.key});

  @override
  State<AdminObrasPage> createState() => _AdminObrasPageState();
}

class _AdminObrasPageState extends State<AdminObrasPage> {
  final AdminService _admin = AdminService.instancia;

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<ObraPendente> _obras = [];
  List<Obra> _obrasPublicadas = [];
  List<Obra> _resultadosPesquisa = [];

  bool _carregando = true;
  String? _erro;
  String? _processandoId;

  // ============================================================
  // PAGINAÇÃO DA PESQUISA
  // ============================================================

  static const int _itensPorPagina = 10;

  int _paginaPesquisaAtual = 1;

  int get _totalPaginasPesquisa {
    if (_resultadosPesquisa.isEmpty) {
      return 1;
    }

    return (_resultadosPesquisa.length / _itensPorPagina).ceil();
  }

  List<Obra> get _resultadosPesquisaDaPagina {
    final inicio =
        (_paginaPesquisaAtual - 1) * _itensPorPagina;

    if (inicio >= _resultadosPesquisa.length) {
      return [];
    }

    final fim = (inicio + _itensPorPagina)
        .clamp(0, _resultadosPesquisa.length);

    return _resultadosPesquisa.sublist(inicio, fim);
  }

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARREGAR
  // ============================================================

  Future<void> _carregar() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final obrasPendentes =
      await _admin.carregarObrasPendentes();

      final obrasPublicadas =
      await _admin.carregarObrasPublicadas();

      if (!mounted) return;

      setState(() {
        _obras = obrasPendentes;
        _obrasPublicadas = obrasPublicadas;
        _resultadosPesquisa = [];
        _paginaPesquisaAtual = 1;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(e);
        _carregando = false;
      });
    }
  }

  // ============================================================
  // PESQUISA
  // ============================================================

  void _pesquisarObras(String texto) {
    final pesquisa = texto.trim().toLowerCase();

    if (pesquisa.isEmpty) {
      setState(() {
        _resultadosPesquisa = [];
        _paginaPesquisaAtual = 1;
      });
      return;
    }

    final resultados = _obrasPublicadas.where((obra) {
      final titulo = obra.titulo.toLowerCase();
      final autor = obra.autor.toLowerCase();
      final categoria = obra.categoria.toLowerCase();

      return titulo.contains(pesquisa) ||
          autor.contains(pesquisa) ||
          categoria.contains(pesquisa);
    }).toList();

    setState(() {
      _resultadosPesquisa = resultados;
      _paginaPesquisaAtual = 1;
    });
  }

  void _limparPesquisa() {
    _pesquisaController.clear();

    setState(() {
      _resultadosPesquisa = [];
      _paginaPesquisaAtual = 1;
    });
  }

  // ============================================================
  // DETALHES DA OBRA PUBLICADA
  // ============================================================

  Future<void> _abrirDetalhesObra(Obra obra) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final processando = _processandoId == obra.id;

        return AlertDialog(
          title: const Text('Detalhes da obra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obra.titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                _DetalheLinha(
                  icone: Icons.person_outline,
                  titulo: 'Autor',
                  valor: obra.autor,
                ),

                const SizedBox(height: 10),

                _DetalheLinha(
                  icone: Icons.category_outlined,
                  titulo: 'Categoria',
                  valor: obra.categoria,
                ),

                if (obra.anoObra != null) ...[
                  const SizedBox(height: 10),

                  _DetalheLinha(
                    icone: Icons.calendar_today_outlined,
                    titulo: 'Ano',
                    valor: obra.anoObra.toString(),
                  ),
                ],

                const SizedBox(height: 10),

                _DetalheLinha(
                  icone: Icons.public_outlined,
                  titulo: 'Publicada em',
                  valor: _formatarData(
                    obra.dataPublicacao,
                  ),
                ),

                if (obra.numeroPaginas != null) ...[
                  const SizedBox(height: 10),

                  _DetalheLinha(
                    icone: Icons.description_outlined,
                    titulo: 'Páginas',
                    valor:
                    '${obra.numeroPaginas} página(s)',
                  ),
                ],

                if (obra.descricao != null &&
                    obra.descricao!.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),

                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(obra.descricao!),
                ],

                if (processando) ...[
                  const SizedBox(height: 24),

                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: processando
                  ? null
                  : () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fechar'),
            ),

            FilledButton.icon(
              onPressed: processando
                  ? null
                  : () async {
                final confirmar = await _confirmar(
                  titulo: 'Deletar obra publicada',
                  mensagem:
                  'Deseja deletar definitivamente '
                      'esta obra?\n\n'
                      'O registo, o PDF, a capa e a presença '
                      'da obra no site serão removidos.\n\n'
                      'Esta ação não pode ser desfeita.',
                  textoConfirmar: 'Deletar',
                );

                if (!confirmar) return;

                if (!mounted) return;

                Navigator.of(dialogContext).pop();

                await _executarDelecao(obra);
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text('Deletar'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // EXECUTAR DELEÇÃO
  // ============================================================

  Future<void> _executarDelecao(Obra obra) async {
    final id = obra.id.trim();

    if (id.isEmpty) {
      _mostrarErro('ID da obra inválido.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _processandoId = id;
      _erro = null;
    });

    try {
      await _admin.deletarObraPublicada(id);

      if (!mounted) return;

      setState(() {
        _obrasPublicadas.removeWhere(
              (item) => item.id == id,
        );

        _resultadosPesquisa.removeWhere(
              (item) => item.id == id,
        );

        _processandoId = null;

        if (_paginaPesquisaAtual > _totalPaginasPesquisa) {
          _paginaPesquisaAtual = _totalPaginasPesquisa;
        }
      });

      _pesquisaController.clear();

      setState(() {
        _resultadosPesquisa = [];
        _paginaPesquisaAtual = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra deletada com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = _mensagemErro(e);

      setState(() {
        _processandoId = null;
        _erro = mensagem;
      });

      _mostrarErro(mensagem);
    }
  }

  // ============================================================
  // SOLICITAÇÕES DE REMOÇÃO
  // ============================================================

  Future<void> _abrirSolicitacoesRemocao() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const AdminSolicitacoesRemocaoPage(),
      ),
    );
  }

  // ============================================================
  // APROVAR
  // ============================================================

  Future<void> _aprovar(
      ObraPendente obra,
      ) async {
    final id = obra.id;

    if (id == null || id.isEmpty) {
      _mostrarErro('ID da obra inválido.');
      return;
    }

    final confirmar = await _confirmar(
      titulo: 'Aprovar publicação',
      mensagem:
      'Deseja aprovar esta obra e '
          'disponibilizá-la publicamente?',
      textoConfirmar: 'Aprovar',
    );

    if (!confirmar) return;

    if (!mounted) return;

    setState(() {
      _processandoId = id;
      _erro = null;
    });

    try {
      final obraPublicada =
      await _admin.aprovarObra(id);

      if (!mounted) return;

      setState(() {
        _obras.removeWhere(
              (item) => item.id == id,
        );

        _obrasPublicadas.insert(
          0,
          obraPublicada,
        );

        _processandoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra aprovada e publicada com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = _mensagemErro(e);

      setState(() {
        _processandoId = null;
        _erro = mensagem;
      });

      _mostrarErro(mensagem);
    }
  }

  // ============================================================
  // REJEITAR
  // ============================================================

  Future<void> _rejeitar(
      ObraPendente obra,
      ) async {
    final id = obra.id;

    if (id == null || id.isEmpty) {
      _mostrarErro('ID da obra inválido.');
      return;
    }

    final confirmar = await _confirmar(
      titulo: 'Rejeitar publicação',
      mensagem:
      'Deseja rejeitar esta obra? '
          'O documento pendente será removido.',
      textoConfirmar: 'Rejeitar',
    );

    if (!confirmar) return;

    if (!mounted) return;

    setState(() {
      _processandoId = id;
      _erro = null;
    });

    try {
      await _admin.rejeitarObra(id);

      if (!mounted) return;

      setState(() {
        _obras.removeWhere(
              (item) => item.id == id,
        );

        _processandoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra rejeitada com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = _mensagemErro(e);

      setState(() {
        _processandoId = null;
        _erro = mensagem;
      });

      _mostrarErro(mensagem);
    }
  }

  // ============================================================
  // EXCLUIR PUBLICAÇÃO PENDENTE
  // ============================================================

  Future<void> _excluir(
      ObraPendente obra,
      ) async {
    final id = obra.id;

    if (id == null || id.isEmpty) {
      _mostrarErro('ID da obra inválido.');
      return;
    }

    final confirmar = await _confirmar(
      titulo: 'Excluir publicação',
      mensagem:
      'Deseja excluir definitivamente '
          'esta publicação pendente?',
      textoConfirmar: 'Excluir',
    );

    if (!confirmar) return;

    if (!mounted) return;

    setState(() {
      _processandoId = id;
      _erro = null;
    });

    try {
      await _admin.excluirObra(id);

      if (!mounted) return;

      setState(() {
        _obras.removeWhere(
              (item) => item.id == id,
        );

        _processandoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Publicação excluída com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = _mensagemErro(e);

      setState(() {
        _processandoId = null;
        _erro = mensagem;
      });

      _mostrarErro(mensagem);
    }
  }

  // ============================================================
  // CONFIRMAÇÃO
  // ============================================================

  Future<bool> _confirmar({
    required String titulo,
    required String mensagem,
    required String textoConfirmar,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  // ============================================================
  // ERROS
  // ============================================================

  String _mensagemErro(Object erro) {
    final mensagem = erro.toString();

    if (mensagem.startsWith('Exception: ')) {
      return mensagem.substring(
        'Exception: '.length,
      );
    }

    return mensagem;
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  String _formatarData(DateTime? data) {
    if (data == null) return '—';

    final local = data.toLocal();

    final dia =
    local.day.toString().padLeft(2, '0');

    final mes =
    local.month.toString().padLeft(2, '0');

    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed:
            _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          // ========================================================
          // BARRA DE PESQUISA — TOPO
          // ========================================================

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: BarraPesquisa(
                controller:
                _pesquisaController,
                hintText:
                'Pesquisar obra, autor ou categoria...',
                onPesquisar: () {
                  _pesquisarObras(
                    _pesquisaController.text,
                  );
                },
                onLimpar: _limparPesquisa,
                onChanged: _pesquisarObras,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ========================================================
          // RESULTADOS DA PESQUISA
          // ========================================================

          if (_pesquisaController.text
              .trim()
              .isNotEmpty) ...[
            if (_resultadosPesquisa.isEmpty)
              _buildNenhumResultado()
            else ...[
              ..._resultadosPesquisaDaPagina
                  .map(_buildResultadoPesquisa),

              // ==================================================
              // PAGINAÇÃO — FINAL DOS RESULTADOS
              // ==================================================

              if (_totalPaginasPesquisa > 1)
                Paginacao(
                  paginaAtual:
                  _paginaPesquisaAtual,
                  totalPaginas:
                  _totalPaginasPesquisa,
                  onPaginaChanged: (pagina) {
                    setState(() {
                      _paginaPesquisaAtual =
                          pagina;
                    });
                  },
                ),
            ],

            const SizedBox(height: 24),
          ],

          // ========================================================
          // ERRO
          // ========================================================

          if (_erro != null) ...[
            _MensagemErroWidget(
              mensagem: _erro!,
              onFechar: () {
                setState(() {
                  _erro = null;
                });
              },
            ),

            const SizedBox(height: 16),
          ],

          // ========================================================
          // SOLICITAÇÕES DE REMOÇÃO
          // ========================================================

          _buildSolicitacoesRemocaoCard(),

          const SizedBox(height: 30),

          // ========================================================
          // PUBLICAÇÕES PENDENTES
          // ========================================================

          Text(
            'Publicações pendentes',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 8),

          Text(
            _obras.isEmpty
                ? 'Não existem publicações aguardando análise.'
                : '${_obras.length} publicação(ões) aguardando análise.',
          ),

          const SizedBox(height: 24),

          if (_obras.isEmpty)
            _buildSemPublicacoes()
          else
            ..._obras.map(_buildObraCard),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTADO DA PESQUISA
  // ============================================================

  Widget _buildResultadoPesquisa(Obra obra) {
    return ObraListaItem(
      obra: obra,
      onTap: () => _abrirDetalhesObra(obra),
    );
  }

  // ============================================================
  // NENHUM RESULTADO
  // ============================================================

  Widget _buildNenhumResultado() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 35,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 50,
            color: Colors.black38,
          ),

          const SizedBox(height: 12),

          Text(
            'Nenhuma obra encontrada.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOLICITAÇÕES DE REMOÇÃO
  // ============================================================

  Widget _buildSolicitacoesRemocaoCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(8),
        side: const BorderSide(
          color: Color(0xFFE2E2E2),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(8),
        onTap:
        _abrirSolicitacoesRemocao,
        child: Padding(
          padding:
          const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFF3F3F3),
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicitações de remoção',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Analisar pedidos de remoção enviados pelos utilizadores.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEM PUBLICAÇÕES
  // ============================================================

  Widget _buildSemPublicacoes() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 55,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 56,
          ),

          const SizedBox(height: 16),

          Text(
            'Não existem publicações pendentes.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTÃO DE OBRA PENDENTE
  // ============================================================

  Widget _buildObraCard(
      ObraPendente obra,
      ) {
    final id = obra.id;

    final processando =
        id != null && _processandoId == id;

    return Card(
      margin:
      const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              obra.titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),

            const SizedBox(height: 12),

            _InfoLinha(
              icone: Icons.person_outline,
              texto: obra.autor,
            ),

            const SizedBox(height: 6),

            _InfoLinha(
              icone:
              Icons.category_outlined,
              texto: obra.categoria,
            ),

            if (obra.anoObra != null) ...[
              const SizedBox(height: 6),

              _InfoLinha(
                icone:
                Icons.calendar_today_outlined,
                texto:
                obra.anoObra.toString(),
              ),
            ],

            const SizedBox(height: 6),

            _InfoLinha(
              icone: Icons.schedule_outlined,
              texto:
              'Enviada em ${_formatarData(obra.dataPublicacao)}',
            ),

            if (obra.descricao != null &&
                obra.descricao!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(height: 16),

              Text(
                obra.descricao!,
                maxLines: 5,
                overflow:
                TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 20),

            if (processando)
              const Align(
                alignment:
                Alignment.centerRight,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _rejeitar(obra),
                    child:
                    const Text('Rejeitar'),
                  ),

                  OutlinedButton(
                    onPressed: () =>
                        _excluir(obra),
                    child:
                    const Text('Excluir'),
                  ),

                  FilledButton(
                    onPressed: () =>
                        _aprovar(obra),
                    child:
                    const Text('Aprovar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LINHA DE DETALHE
// ============================================================

class _DetalheLinha
    extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _DetalheLinha({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icone,
          size: 19,
        ),

        const SizedBox(width: 9),

        Expanded(
          child: RichText(
            text: TextSpan(
              style:
              DefaultTextStyle.of(context)
                  .style,
              children: [
                TextSpan(
                  text: '$titulo: ',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                TextSpan(
                  text: valor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LINHA DE INFORMAÇÃO
// ============================================================

class _InfoLinha
    extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _InfoLinha({
    required this.icone,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icone,
          size: 18,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(texto),
        ),
      ],
    );
  }
}

// ============================================================
// MENSAGEM DE ERRO
// ============================================================

class _MensagemErroWidget
    extends StatelessWidget {
  final String mensagem;
  final VoidCallback onFechar;

  const _MensagemErroWidget({
    required this.mensagem,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .errorContainer,
      borderRadius:
      BorderRadius.circular(8),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context)
                  .colorScheme
                  .onErrorContainer,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                mensagem,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onErrorContainer,
                ),
              ),
            ),

            IconButton(
              onPressed: onFechar,
              icon:
              const Icon(Icons.close),
              color: Theme.of(context)
                  .colorScheme
                  .onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}

