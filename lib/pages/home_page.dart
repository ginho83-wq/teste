import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ObrasRepository _obrasRepository = ObrasRepository.instancia;
  final AuthService _authService = AuthService.instancia;

  final TextEditingController _pesquisaController =
  TextEditingController();

  List<Obra> _obrasRecentes = [];
  bool _carregandoObras = true;

  @override
  void initState() {
    super.initState();
    _carregarObrasRecentes();
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
        limite: 2,
      );

      if (!mounted) return;

      setState(() {
        _obrasRecentes = obras;
        _carregandoObras = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _obrasRecentes = [];
        _carregandoObras = false;
      });
    }
  }

  void _pesquisar() {
    final termo = _pesquisaController.text.trim();

    if (termo.isEmpty) {
      context.go('/acervo');
      return;
    }

    context.go(
      '/search/${Uri.encodeComponent(termo)}',
    );
  }

  void _abrirCategoria(String categoria) {
    context.go(
      '/categoria/${Uri.encodeComponent(categoria)}',
    );
  }

  void _abrirObra(Obra obra) {
    if (obra.id.isEmpty) return;

    context.go('/acervo?obra=${obra.id}');
  }

  Future<void> _sair() async {
    await _authService.sair();

    if (!mounted) return;

    context.go('/');
  }

  String _nomeUtilizador() {
    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      return 'Conta';
    }

    final metadata = usuario.userMetadata;

    final nome =
        metadata?['nome'] ??
            metadata?['full_name'] ??
            metadata?['name'];

    if (nome != null && nome.toString().trim().isNotEmpty) {
      return nome.toString().trim();
    }

    return usuario.email ?? 'Conta';
  }

  String? _urlAvatar() {
    final usuario = Supabase.instance.client.auth.currentUser;

    if (usuario == null) return null;

    final metadata = usuario.userMetadata;

    final avatar =
        metadata?['avatar_url'] ??
            metadata?['picture'];

    if (avatar == null) return null;

    final valor = avatar.toString().trim();

    return valor.isEmpty ? null : valor;
  }

  @override
  Widget build(BuildContext context) {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    final autenticado = usuario != null;
    final nome = _nomeUtilizador();
    final avatar = _urlAvatar();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(
        context,
        autenticado: autenticado,
        nome: nome,
        avatar: avatar,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHero(),

              const SizedBox(height: 34),

              _buildCategorias(),

              const SizedBox(height: 58),

              _buildObrasRecentes(),

              const SizedBox(height: 64),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, {
        required bool autenticado,
        required String nome,
        required String? avatar,
      }) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 72,
      title: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1080,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.go('/'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Text(
                    'Obra Livre',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  context.go('/acervo');
                },
                child: const Text('Biblioteca'),
              ),

              const SizedBox(width: 8),

              if (autenticado)
                TextButton(
                  onPressed: () {
                    context.go('/publicar');
                  },
                  child: const Text('Publicar'),
                ),

              const SizedBox(width: 8),

              if (!autenticado)
                FilledButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: const Text('Entrar'),
                )
              else
                _buildAvatarMenu(
                  context,
                  nome: nome,
                  avatar: avatar,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarMenu(
      BuildContext context, {
        required String nome,
        required String? avatar,
      }) {
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      offset: const Offset(0, 48),
      onSelected: (valor) {
        switch (valor) {
          case 'conta':
            context.go('/minha-conta');
            break;

          case 'configuracoes':
            context.go('/configuracoes');
            break;

          case 'sair':
            _sair();
            break;
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem<String>(
            value: 'conta',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline),
              title: Text('Minha conta'),
            ),
          ),
          PopupMenuItem<String>(
            value: 'configuracoes',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.settings_outlined),
              title: Text('Configurações'),
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'sair',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout),
              title: Text('Sair'),
            ),
          ),
        ];
      },
      child: CircleAvatar(
        radius: 18,
        backgroundImage:
        avatar != null ? NetworkImage(avatar) : null,
        child: avatar == null
            ? Text(
          nome.isNotEmpty
              ? nome.substring(0, 1).toUpperCase()
              : 'U',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildHero() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1080,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            64,
            24,
            0,
          ),
          child: Column(
            children: [
              const Text(
                'Encontre conhecimento. Encontre obras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Pesquise teses, dissertações, artigos e outras obras académicas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                child: TextField(
                  controller: _pesquisaController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _pesquisar(),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar obras académicas',
                    prefixIcon: const Icon(
                      Icons.search,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Pesquisar',
                      onPressed: _pesquisar,
                      icon: const Icon(
                        Icons.arrow_forward,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
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

  Widget _buildCategorias() {
    const categorias = [
      'Tese de Doutoramento',
      'Tese de Mestrado',
      'Monografia',
      'Artigos Científicos',
      'Literatura',
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1080,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: categorias.map((categoria) {
              return TextButton(
                onPressed: () {
                  _abrirCategoria(categoria);
                },
                child: Text(categoria),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildObrasRecentes() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1080,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Publicações recentes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: () {
                      context.go('/acervo');
                    },
                    child: const Text(
                      'Ver biblioteca',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_carregandoObras)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 40,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_obrasRecentes.isEmpty)
                _buildEstadoVazio()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children: _obrasRecentes
                            .map(_buildObraCard)
                            .toList(),
                      );
                    }

                    return Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: _obrasRecentes
                          .map(
                            (obra) => Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.only(
                              right: 8,
                            ),
                            child:
                            _buildObraCard(obra),
                          ),
                        ),
                      )
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObraCard(Obra obra) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirObra(obra),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                obra.categoria,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                obra.titulo,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                obra.autor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),

              if (obra.anoObra != null) ...[
                const SizedBox(height: 5),
                Text(
                  obra.anoObra.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],

              if (obra.descricao != null &&
                  obra.descricao!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  obra.descricao!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver obra',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 42,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 34,
            color: Colors.black45,
          ),
          SizedBox(height: 12),
          Text(
            'Ainda não existem publicações disponíveis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1080,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 28,
            ),
            child: Row(
              children: [
                const Text(
                  '© Obra Livre',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),

                const Spacer(),

                TextButton(
                  onPressed: () {
                    context.go('/politica-privacidade');
                  },
                  child: const Text(
                    'Privacidade',
                  ),
                ),

                TextButton(
                  onPressed: () {
                    context.go('/termos');
                  },
                  child: const Text(
                    'Termos',
                  ),
                ),

                TextButton(
                  onPressed: () {
                    context.go('/contacto');
                  },
                  child: const Text(
                    'Contacto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

