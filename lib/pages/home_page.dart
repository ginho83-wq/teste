import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  final AuthService _authService =
      AuthService.instancia;

  final HistoricoObrasService _historicoService =
  HistoricoObrasService();

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obrasRecentes = [];
  List<dynamic> _historicoRecente = [];

  bool _carregandoObras = true;
  bool _carregandoHistorico = true;
  bool _ehAdmin = false;
  bool _carregandoPerfil = true;

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();

    _carregarObrasRecentes();
    _carregarHistoricoRecente();
    _verificarAdministrador();
    _carregarAvatar();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  void _carregarAvatar() {
    final usuario = _authService.usuarioAtual;

    if (usuario == null) return;

    final metadata = usuario.userMetadata;

    final possiveisUrls = [
      metadata?['avatar_url'],
      metadata?['picture'],
      metadata?['photo_url'],
    ];

    for (final valor in possiveisUrls) {
      if (valor is String && valor.trim().isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _avatarUrl = valor.trim();
        });

        return;
      }
    }
  }

  Future<void> _carregarObrasRecentes() async {
    try {
      final obras =
      await _obrasRepository.carregarObras(
        pagina: 1,
        limite: 2,
      );

      if (!mounted) return;

      setState(() {
        _obrasRecentes = obras;
        _carregandoObras = false;
      });
    } catch (e) {
      debugPrint(
        'Erro ao carregar publicações recentes: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregandoObras = false;
      });
    }
  }

  Future<void> _carregarHistoricoRecente() async {
    try {
      final historico =
      await _historicoService.obterHistorico();

      if (!mounted) return;

      setState(() {
        _historicoRecente =
            historico.take(3).toList();

        _carregandoHistorico = false;
      });
    } catch (e) {
      debugPrint(
        'Erro ao carregar histórico recente: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregandoHistorico = false;
      });
    }
  }

  Future<void> _verificarAdministrador() async {
    try {
      final ehAdmin =
      await _authService.ehAdmin();

      if (!mounted) return;

      setState(() {
        _ehAdmin = ehAdmin;
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

  Future<void> _abrirObra(Obra obra) async {
    if (obra.id.isEmpty) return;

    try {
      await _historicoService.registrarConsulta(
        obraId: obra.id,
      );

      await _carregarHistoricoRecente();
    } catch (e) {
      debugPrint(
        'Erro ao registar consulta: $e',
      );
    }

    if (!mounted) return;

    context.go(
      '/acervo?obra=${Uri.encodeComponent(obra.id)}',
    );
  }

  void _pesquisar() {
    final texto =
    _pesquisaController.text.trim();

    if (texto.isEmpty) return;

    context.go(
      '/search/${Uri.encodeComponent(texto)}',
    );
  }

  void _abrirHistorico() {
    context.go('/historico-obras');
  }

  void _abrirCategoria(String categoria) {
    context.go(
      '/categoria/${Uri.encodeComponent(categoria)}',
    );
  }

  Future<void> _sair() async {
    await _authService.sair();

    if (!mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _carregarObrasRecentes(),
              _carregarHistoricoRecente(),
            ]);
          },
          child: SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 30),

                _buildHero(),

                const SizedBox(height: 28),

                _buildCategorias(),

                const SizedBox(height: 32),

                _buildObrasRecentes(),

                const SizedBox(height: 32),

                _buildHistoricoRecente(),

                const SizedBox(height: 40),

                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'Teste',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),

        const Spacer(),

        TextButton(
          onPressed: () =>
              context.go('/acervo'),
          child: const Text('Acervo'),
        ),

        TextButton(
          onPressed: () =>
              context.go('/publicar'),
          child: const Text('Publicar'),
        ),

        PopupMenuButton<String>(
          onSelected: (valor) {
            switch (valor) {
              case 'conta':
                context.go('/minha-conta');
                break;

              case 'configuracoes':
                context.go('/configuracoes');
                break;

              case 'admin':
                context.go('/admin-obras');
                break;

              case 'historico':
                context.go('/historico-obras');
                break;

              case 'sair':
                _sair();
                break;
            }
          },
          itemBuilder: (context) {
            final itens =
            <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'conta',
                child: Text('Minha conta'),
              ),

              const PopupMenuItem(
                value: 'configuracoes',
                child: Text('Configurações'),
              ),

              const PopupMenuItem(
                value: 'historico',
                child: Text(
                  'Obras consultadas',
                ),
              ),
            ];

            if (_ehAdmin) {
              itens.add(
                const PopupMenuItem(
                  value: 'admin',
                  child: Text(
                    'Administração',
                  ),
                ),
              );
            }

            itens.add(
              const PopupMenuDivider(),
            );

            itens.add(
              const PopupMenuItem(
                value: 'sair',
                child: Text('Sair'),
              ),
            );

            return itens;
          },

          child: _buildAvatar(),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (_avatarUrl != null &&
        _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage:
        NetworkImage(_avatarUrl!),
        onBackgroundImageError:
            (_, __) {
          if (!mounted) return;

          setState(() {
            _avatarUrl = null;
          });
        },
      );
    }

    return const CircleAvatar(
      radius: 18,
      child: Icon(
        Icons.person_outline,
        size: 20,
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Encontre conhecimento.\nEncontre obras.',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Pesquise obras académicas e científicas.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: _pesquisaController,
          onSubmitted: (_) => _pesquisar(),
          decoration: InputDecoration(
            hintText:
            'Pesquisar obras académicas',
            prefixIcon:
            const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: _pesquisar,
              icon: const Icon(
                Icons.arrow_forward,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorias() {
    const categorias = [
      'Tese Doutoramento',
      'Tese Mestrado',
      'Monografia',
      'Artigos Científicos',
      'Literatura',
    ];

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorias',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 14),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
          categorias.map((categoria) {
            return OutlinedButton(
              onPressed: () =>
                  _abrirCategoria(categoria),
              child: Text(categoria),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildObrasRecentes() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Publicações recentes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            TextButton(
              onPressed: () =>
                  context.go('/acervo'),
              child: const Text('Ver todas'),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (_carregandoObras)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child:
              CircularProgressIndicator(),
            ),
          )
        else if (_obrasRecentes.isEmpty)
          _buildEstadoVazio(
            'Ainda não existem publicações recentes.',
          )
        else
          ..._obrasRecentes.map(
            _buildObraRecenteCard,
          ),
      ],
    );
  }

  Widget _buildObraRecenteCard(Obra obra) {
    return Card(
      elevation: 0,
      margin:
      const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(8),
        onTap: () => _abrirObra(obra),
        child: Padding(
          padding:
          const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                  Colors.grey.shade100,
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      obra.titulo,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    if (obra.autor != null &&
                        obra.autor!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        obra.autor!,
                        style: TextStyle(
                          color:
                          Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoricoRecente() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Obras consultadas recentemente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            TextButton(
              onPressed: _abrirHistorico,
              child: const Text(
                'Ver histórico',
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (_carregandoHistorico)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child:
              CircularProgressIndicator(),
            ),
          )
        else if (_historicoRecente.isEmpty)
          _buildEstadoVazio(
            'As obras que consultar aparecerão aqui.',
          )
        else
          ..._historicoRecente.map(
            _buildHistoricoCard,
          ),
      ],
    );
  }

  Widget _buildHistoricoCard(dynamic obra) {
    return Card(
      elevation: 0,
      margin:
      const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(8),
        onTap: () {
          final obraId =
              obra.obraId?.toString() ?? '';

          if (obraId.isEmpty) return;

          context.go(
            '/acervo?obra=${Uri.encodeComponent(obraId)}',
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                  Colors.grey.shade100,
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      obra.titulo,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    if (obra.autor != null &&
                        obra.autor!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        obra.autor!,
                        style: TextStyle(
                          color:
                          Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    if (obra.categoria != null &&
                        obra.categoria!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        obra.categoria!,
                        style: TextStyle(
                          color:
                          Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio(String texto) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        '© ${DateTime.now().year} Teste',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
    );
  }
}
