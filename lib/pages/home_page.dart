import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/auth_service.dart';
import '../services/historico_obras_service.dart';
import '../widgets/avatar_utilizador.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  final AuthService _authService =
      AuthService.instancia;

  final HistoricoObrasService _historicoService =
  HistoricoObrasService();

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obrasRecentes = [];
  List<HistoricoObra> _consultasRecentes = [];

  bool _carregandoObras = true;
  bool _carregandoConsultas = true;
  bool _ehAdmin = false;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();

    _carregarObrasRecentes();
    _carregarConsultasRecentes();
    _verificarAdministrador();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _carregarConsultasRecentes();
    });
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarObrasRecentes() async {
    try {
      final obras = await _obrasRepository.carregarObras(
        pagina: 1,
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _obrasRecentes = obras;
        _carregandoObras = false;
      });

      debugPrint(
        'HOME: ${obras.length} publicações recentes encontradas.',
      );
    } catch (e) {
      debugPrint(
        'HOME: erro ao carregar publicações recentes: $e',
      );

      if (!mounted) return;

      setState(() {
        _obrasRecentes = [];
        _carregandoObras = false;
      });
    }
  }

  Future<void> _carregarConsultasRecentes() async {
    try {
      final utilizador =
          Supabase.instance.client.auth.currentUser;

      if (utilizador == null) {
        if (!mounted) return;

        setState(() {
          _consultasRecentes = [];
          _carregandoConsultas = false;
        });

        return;
      }

      if (mounted) {
        setState(() {
          _carregandoConsultas = true;
        });
      }

      final consultas =
      await _historicoService.obterConsultasRecentes(
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _consultasRecentes = consultas;
        _carregandoConsultas = false;
      });

      debugPrint(
        'HOME: ${consultas.length} obras consultadas encontradas.',
      );
    } catch (e) {
      debugPrint(
        'HOME: erro ao carregar histórico: $e',
      );

      if (!mounted) return;

      setState(() {
        _consultasRecentes = [];
        _carregandoConsultas = false;
      });
    }
  }

  Future<void> _verificarAdministrador() async {
    try {
      final admin = await _authService.ehAdmin();

      if (!mounted) return;

      setState(() {
        _ehAdmin = admin;
        _carregandoPerfil = false;
      });
    } catch (e) {
      debugPrint(
        'HOME: erro ao verificar administrador: $e',
      );

      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
        _carregandoPerfil = false;
      });
    }
  }

  void _executarPesquisa() {
    final pesquisa =
    _pesquisaController.text.trim();

    if (pesquisa.isEmpty) return;

    context.go(
      '/search/${Uri.encodeComponent(pesquisa)}',
    );
  }

  Future<void> _abrirObra(Obra obra) async {
    if (!mounted) return;

    try {
      await _historicoService.registrarConsulta(
        obraId: obra.id,
      );

      debugPrint(
        'HOME: consulta registrada ao abrir detalhes da obra ${obra.id}',
      );
    } catch (e) {
      debugPrint(
        'HOME: erro ao registrar consulta: $e',
      );
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return _buildDetalhesObraDialog(
          obra,
          dialogContext,
        );
      },
    );

    if (!mounted) return;

    await _carregarConsultasRecentes();
  }

  Widget _buildDetalhesObraDialog(
      Obra obra,
      BuildContext dialogContext,
      ) {
    return AlertDialog(
      title: Text(
        obra.titulo,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              if (obra.autor.trim().isNotEmpty) ...[
                const Text(
                  'Autor',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  obra.autor,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Categoria',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                obra.categoria,
                style: const TextStyle(
                  color: Colors.black54,
                ),
              ),
              if (obra.descricao != null &&
                  obra.descricao!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Descrição',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  obra.descricao!,
                  style: const TextStyle(
                    color: Colors.black87,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Fechar'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await _abrirDocumentoNoDialog(
              obra,
              dialogContext,
            );
          },
          icon: const Icon(
            Icons.open_in_new,
            size: 18,
          ),
          label: const Text('Abrir documento'),
        ),
      ],
    );
  }

  Future<void> _abrirDocumentoNoDialog(
      Obra obra,
      BuildContext dialogContext,
      ) async {
    final obraId = obra.id;

    if (obraId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível identificar esta obra.',
            ),
          ),
        );
      }

      return;
    }

    final url = obra.urlDocumento.trim();

    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Esta obra não possui documento disponível.',
            ),
          ),
        );
      }

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'O endereço do documento é inválido.',
            ),
          ),
        );
      }

      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );

      debugPrint(
        'HOME: documento aberto: $abriu',
      );

      if (!abriu) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o documento.',
            ),
          ),
        );

        return;
      }
    } catch (e) {
      debugPrint(
        'HOME: erro ao abrir documento: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );

      return;
    }

    try {
      await _historicoService.registrarConsulta(
        obraId: obraId,
      );

      debugPrint(
        'HOME: consulta atualizada para obra $obraId',
      );
    } catch (e) {
      debugPrint(
        'HOME: erro ao atualizar histórico: $e',
      );
    }

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }

    if (mounted) {
      await _carregarConsultasRecentes();
    }
  }

  Future<void> _abrirConsultaRecente(
      HistoricoObra consulta,
      ) async {
    final obraId = consulta.obraId;

    if (obraId.isEmpty) {
      return;
    }

    final url = consulta.urlDocumento?.trim();

    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);

      if (uri == null ||
          (uri.scheme != 'http' &&
              uri.scheme != 'https')) {
        return;
      }

      try {
        final abriu = await launchUrl(
          uri,
          webOnlyWindowName: '_blank',
        );

        debugPrint(
          'HOME: consulta recente aberta: $abriu',
        );

        if (!abriu) {
          return;
        }
      } catch (e) {
        debugPrint(
          'HOME: erro ao abrir consulta recente: $e',
        );

        return;
      }

      try {
        await _historicoService.registrarConsulta(
          obraId: obraId,
        );

        await _carregarConsultasRecentes();
      } catch (e) {
        debugPrint(
          'HOME: erro ao atualizar histórico: $e',
        );
      }

      return;
    }

    if (!mounted) return;

    context.go(
      '/acervo?obra=${Uri.encodeComponent(obraId)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Obra Livre',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/acervo');
            },
            child: const Text('Acervo'),
          ),

          if (!_carregandoPerfil && _ehAdmin)
            TextButton(
              onPressed: () {
                context.go('/admin-obras');
              },
              child: const Text('Administração'),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 9,
              horizontal: 4,
            ),
            child: TextButton(
              onPressed: () {
                context.go('/publicar');
              },
              style: TextButton.styleFrom(
                backgroundColor:
                const Color(0xffe8f1ff),
                foregroundColor:
                const Color(0xff2457a6),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Publicar',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (valor) async {
              switch (valor) {
                case 'conta':
                  context.go('/minha-conta');
                  break;

                case 'configuracoes':
                  context.go('/configuracoes');
                  break;

                case 'sair':
                  await _authService.sair();

                  if (!mounted) return;

                  context.go('/login');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'conta',
                child: Text('Minha conta'),
              ),
              PopupMenuItem(
                value: 'configuracoes',
                child: Text('Configurações'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'sair',
                child: Text('Sair'),
              ),
            ],
            child: const Padding(
              padding:
              EdgeInsets.symmetric(
                horizontal: 12,
              ),
              child: AvatarUtilizador(
                radius: 17,
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _carregarObrasRecentes(),
            _carregarConsultasRecentes(),
          ]);
        },
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHero(context),
              _buildCategorias(context),
              _buildObrasRecentes(context),
              _buildConsultasRecentes(context),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        24,
        45,
        24,
        30,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 850,
          ),
          child: Column(
            children: [
              const Text(
                'Encontre conhecimento.\nEncontre obras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 28),
              ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 720,
                ),
                child: TextField(
                  controller:
                  _pesquisaController,
                  onSubmitted: (_) {
                    _executarPesquisa();
                  },
                  textInputAction:
                  TextInputAction.search,
                  decoration:
                  InputDecoration(
                    hintText:
                    'Pesquisar obras académicas',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon:
                    const Icon(
                      Icons.search,
                      color: Colors.black54,
                    ),
                    suffixIcon:
                    ValueListenableBuilder<
                        TextEditingValue>(
                      valueListenable:
                      _pesquisaController,
                      builder: (
                          context,
                          value,
                          child,
                          ) {
                        if (value.text.isEmpty) {
                          return const SizedBox
                              .shrink();
                        }

                        return IconButton(
                          tooltip:
                          'Limpar pesquisa',
                          icon:
                          const Icon(
                            Icons.close,
                            size: 20,
                          ),
                          onPressed: () {
                            _pesquisaController
                                .clear();
                          },
                        );
                      },
                    ),
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xffdddddd),
                      ),
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                      borderSide:
                      const BorderSide(
                        color:
                        Color(0xffdddddd),
                      ),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                      borderSide:
                      const BorderSide(
                        color: Colors.black54,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorias(
      BuildContext context,
      ) {
    const categorias = [
      'Tese Doutoramento',
      'Tese Mestrado',
      'Monografia',
      'Artigos Científicos',
      'Literatura',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        10,
        24,
        20,
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children:
        categorias.map((categoria) {
          return InkWell(
            onTap: () {
              context.go(
                '/categoria/${Uri.encodeComponent(categoria)}',
              );
            },
            borderRadius:
            BorderRadius.circular(4),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: Text(
                categoria,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildObrasRecentes(
      BuildContext context,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        30,
        24,
        10,
      ),
      child: ConstrainedBox(
        constraints:
        const BoxConstraints(
          maxWidth: 1100,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Publicações recentes',
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (_carregandoObras)
              const Center(
                child: Padding(
                  padding:
                  EdgeInsets.all(25),
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (_obrasRecentes.isEmpty)
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Text(
                  'Ainda não existem publicações.',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              )
            else
              ..._obrasRecentes.map(
                    (obra) =>
                    _buildObraCard(obra),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObraCard(Obra obra) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(6),
        side: const BorderSide(
          color: Color(0xffe2e2e2),
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(6),
        onTap: () async {
          await _abrirObra(obra);
        },
        child: Padding(
          padding:
          const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 30,
                color: Colors.black54,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      obra.titulo,
                      style:
                      const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      obra.autor,
                      style:
                      const TextStyle(
                        color:
                        Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      obra.categoria,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildConsultasRecentes(
      BuildContext context,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        35,
        24,
        20,
      ),
      child: ConstrainedBox(
        constraints:
        const BoxConstraints(
          maxWidth: 1100,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Obras consultadas recentemente',
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (_carregandoConsultas)
              const Center(
                child: Padding(
                  padding:
                  EdgeInsets.all(25),
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (_consultasRecentes.isEmpty)
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Text(
                  'Ainda não consultou nenhuma obra.',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              )
            else
              ..._consultasRecentes.map(
                    (consulta) =>
                    _buildConsultaCard(
                      consulta,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultaCard(
      HistoricoObra consulta,
      ) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 0,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(6),
        side: const BorderSide(
          color: Color(0xffe2e2e2),
        ),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: const Icon(
          Icons.history,
          color: Colors.black54,
        ),
        title: Text(
          consulta.titulo,
          style: const TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (consulta.autor != null)
              Text(
                consulta.autor!,
              ),
            if (consulta.categoria != null)
              Text(
                consulta.categoria!,
                style:
                const TextStyle(
                  fontSize: 12,
                  color:
                  Colors.black45,
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.open_in_new,
          size: 20,
        ),
        onTap: () async {
          await _abrirConsultaRecente(
            consulta,
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        top: 50,
      ),
      padding:
      const EdgeInsets.all(30),
      color:
      const Color(0xfff5f5f5),
      child: const Center(
        child: Text(
          'Obra Livre',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

