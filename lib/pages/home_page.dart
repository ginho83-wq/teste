import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/auth_service.dart';
import '../services/historico_obras_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ObrasRepository _obrasRepository = ObrasRepository.instancia;

  final AuthService _authService = AuthService.instancia;

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

  // ============================================================
  // PUBLICAÇÕES RECENTES
  // ============================================================

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

  // ============================================================
  // OBRAS CONSULTADAS RECENTEMENTE
  // ============================================================

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

  // ============================================================
  // VERIFICAR ADMINISTRADOR
  // ============================================================

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
        'Erro ao verificar administrador: $e',
      );

      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
        _carregandoPerfil = false;
      });
    }
  }

  // ============================================================
  // PESQUISA
  // ============================================================

  void _executarPesquisa() {
    final pesquisa =
    _pesquisaController.text.trim();

    if (pesquisa.isEmpty) return;

    context.go(
      '/search/${Uri.encodeComponent(pesquisa)}',
    );
  }

  // ============================================================
  // ABRIR OBRA
  // ============================================================

  Future<void> _abrirObra(Obra obra) async {
    final obraId = obra.id;

    if (obraId == null || obraId.isEmpty) {
      return;
    }

    try {
      await _historicoService.registrarConsulta(
        obraId: obraId,
      );

      debugPrint(
        'HOME: consulta registrada para obra $obraId',
      );
    } catch (e) {
      debugPrint(
        'HOME: erro ao registrar consulta: $e',
      );
    }

    await _carregarConsultasRecentes();

    if (!mounted) return;

    context.go(
      '/acervo?obra=${Uri.encodeComponent(obraId)}',
    );
  }

  // ============================================================
  // ABRIR CONSULTA RECENTE
  // ============================================================

  Future<void> _abrirConsultaRecente(
      HistoricoObra consulta,
      ) async {
    final obraId = consulta.obraId;

    if (obraId.isEmpty) {
      return;
    }

    try {
      await _historicoService.registrarConsulta(
        obraId: obraId,
      );

      final url =
      consulta.urlDocumento?.trim();

      if (url != null && url.isNotEmpty) {
        final uri = Uri.tryParse(url);

        if (uri != null) {
          await launchUrl(
            uri,
            webOnlyWindowName: '_blank',
          );
        }
      } else {
        if (!mounted) return;

        context.go(
          '/acervo?obra=${Uri.encodeComponent(obraId)}',
        );
      }

      await _carregarConsultasRecentes();
    } catch (e) {
      debugPrint(
        'Erro ao abrir consulta recente: $e',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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

          // ====================================================
          // BOTÃO PUBLICAR
          // ====================================================

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
                  fontWeight: FontWeight.w600,
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

                case 'historico':
                  context.go('/historico-obras');
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

              PopupMenuItem(
                value: 'historico',
                child: Text('Histórico de obras'),
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
              child: CircleAvatar(
                radius: 17,
                child: Icon(
                  Icons.person_outline,
                ),
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

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,

      color: Colors.white,

      // Espaçamento reduzido para aproximar
      // as categorias da pesquisa.
      padding: const EdgeInsets.fromLTRB(
        24,
        45,
        24,
        30,
      ),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
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
                constraints: const BoxConstraints(
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

                  decoration: InputDecoration(
                    hintText:
                    'Pesquisar obras académicas',

                    filled: true,
                    fillColor: Colors.white,

                    prefixIcon: const Icon(
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
                          return const SizedBox.shrink();
                        }

                        return IconButton(
                          tooltip:
                          'Limpar pesquisa',

                          icon: const Icon(
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
                    const EdgeInsets.symmetric(
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

  // ============================================================
  // CATEGORIAS
  // ============================================================

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
      // Reduzido de 35 para 10 para aproximar
      // as categorias da barra de pesquisa.
      padding: const EdgeInsets.fromLTRB(
        24,
        10,
        24,
        20,
      ),

      child: Wrap(
        spacing: 24,
        runSpacing: 12,

        alignment:
        WrapAlignment.center,

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

  // ============================================================
  // PUBLICAÇÕES RECENTES
  // ============================================================

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

  // ============================================================
  // CARD DA OBRA
  // ============================================================

  Widget _buildObraCard(
      Obra obra,
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

        side:
        const BorderSide(
          color:
          Color(0xffe2e2e2),
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

                    if (obra.autor != null)
                      Text(
                        obra.autor!,

                        style:
                        const TextStyle(
                          color:
                          Colors.black54,
                        ),
                      ),

                    if (obra.categoria != null)
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          top: 4,
                        ),

                        child: Text(
                          obra.categoria!,

                          style:
                          const TextStyle(
                            fontSize: 13,
                            color:
                            Colors.black45,
                          ),
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

  // ============================================================
  // OBRAS CONSULTADAS RECENTEMENTE
  // ============================================================

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

  // ============================================================
  // CARD DO HISTÓRICO
  // ============================================================

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

        side:
        const BorderSide(
          color:
          Color(0xffe2e2e2),
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

          style:
          const TextStyle(
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

  // ============================================================
  // FOOTER
  // ============================================================

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
