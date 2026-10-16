import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instancia;

  bool _carregando = true;
  bool _carregandoCitacoes = false;

  String? _erro;
  String? _erroCitacoes;

  Map<String, dynamic>? _perfil;

  List<Map<String, dynamic>> _obras = [];
  List<Map<String, dynamic>> _obrasPendentes = [];
  List<Map<String, dynamic>> _historico = [];

  int _totalCitacoes = 0;
  Map<String, int> _citacoesPorObra = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final utilizador = _supabase.auth.currentUser;

      if (utilizador == null) {
        if (mounted) context.go('/login');
        return;
      }

      final perfilResultado = await _supabase
          .from('profiles')
          .select()
          .eq('id', utilizador.id)
          .maybeSingle();

      final obrasResultado = await _supabase
          .from('obras')
          .select('id, titulo, autor, categoria, created_at')
          .eq('user_id', utilizador.id)
          .order('created_at', ascending: false);

      final pendentesResultado = await _supabase
          .from('obras_pendentes')
          .select()
          .eq('user_id', utilizador.id);

      if (!mounted) return;

      setState(() {
        _perfil = perfilResultado;

        _obras = List<Map<String, dynamic>>.from(
          obrasResultado,
        );

        _obrasPendentes = List<Map<String, dynamic>>.from(
          pendentesResultado,
        );

        _carregando = false;
      });

      // Carrega as estatísticas e o histórico separadamente.
      await Future.wait([
        _carregarCitacoes(),
        _carregarHistorico(utilizador.id),
      ]);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar os dados da conta.';
        _carregando = false;
      });

      debugPrint('Erro ao carregar MinhaContaPage: $e');
    }
  }

  /// Carrega as citações associadas às obras publicadas
  /// pelo utilizador autenticado.
  Future<void> _carregarCitacoes() async {
    if (!mounted) return;

    setState(() {
      _carregandoCitacoes = true;
      _erroCitacoes = null;
    });

    try {
      final utilizador = _supabase.auth.currentUser;

      if (utilizador == null) {
        throw Exception('É necessário iniciar sessão.');
      }

      // Não existem citações a contabilizar sem obras publicadas.
      if (_obras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _totalCitacoes = 0;
          _citacoesPorObra = {};
          _carregandoCitacoes = false;
        });

        return;
      }

      final idsObras = _obras
          .map((obra) => obra['id'])
          .where((id) => id != null)
          .map((id) => id.toString())
          .toSet()
          .toList();

      if (idsObras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _totalCitacoes = 0;
          _citacoesPorObra = {};
          _carregandoCitacoes = false;
        });

        return;
      }

      // Consulta os registos da tabela citacoes_obras
      // associados aos identificadores das obras do utilizador.
      final resultado = await _supabase
          .from('citacoes_obras')
          .select('id, obra_id')
          .inFilter('obra_id', idsObras);

      final registos = List<Map<String, dynamic>>.from(
        resultado,
      );

      final Map<String, int> contagem = {};

      for (final registo in registos) {
        final obraId = registo['obra_id']?.toString();

        if (obraId == null || obraId.isEmpty) continue;

        contagem[obraId] = (contagem[obraId] ?? 0) + 1;
      }

      if (!mounted) return;

      setState(() {
        _citacoesPorObra = contagem;
        _totalCitacoes = registos.length;
        _carregandoCitacoes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erroCitacoes =
        'Não foi possível carregar as estatísticas de citações.';
        _carregandoCitacoes = false;
      });

      debugPrint('Erro ao carregar citações das obras: $e');
    }
  }

  Future<void> _carregarHistorico(String utilizadorId) async {
    try {
      final resultado = await _supabase
          .from('historico_obras_consultadas')
          .select()
          .eq('user_id', utilizadorId)
          .order('data_consulta', ascending: false)
          .limit(5);

      if (!mounted) return;

      setState(() {
        _historico = List<Map<String, dynamic>>.from(
          resultado,
        );
      });
    } catch (e) {
      // O histórico não deve impedir a abertura da Minha Conta.
      debugPrint('Não foi possível carregar o histórico: $e');
    }
  }

  Future<void> _sair() async {
    try {
      await _supabase.auth.signOut();

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível terminar a sessão.'),
        ),
      );
    }
  }

  void _abrirConta() {
    context.go('/minha-conta');
  }

  void _abrirConfiguracoes() {
    context.push('/configuracoes');
  }

  void _abrirEstatisticas() {
    context.push('/estatisticas');
  }

  void _abrirObra(dynamic id) {
    if (id == null) return;
    context.push('/obra/$id');
  }

  String _texto(
      dynamic valor, {
        String alternativa = 'Não indicado',
      }) {
    if (valor == null || valor.toString().trim().isEmpty) {
      return alternativa;
    }

    return valor.toString();
  }

  String _nomeUtilizador() {
    final nome = _perfil?['nome'] ??
        _perfil?['nome_completo'] ??
        _perfil?['full_name'];

    if (nome != null && nome.toString().trim().isNotEmpty) {
      return nome.toString();
    }

    return _supabase.auth.currentUser?.email ?? 'Utilizador';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: _construirAppBar(),
      body: _construirCorpo(),
    );
  }

  PreferredSizeWidget _construirAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFEAF4FF),
      foregroundColor: const Color(0xFF17365D),
      elevation: 0,
      title: const Text(
        'Minha Conta',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Menu da conta',
          icon: const Icon(Icons.account_circle_outlined),
          onSelected: (valor) {
            switch (valor) {
              case 'conta':
                _abrirConta();
                break;
              case 'configuracoes':
                _abrirConfiguracoes();
                break;
              case 'sair':
                _sair();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'conta',
              child: ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('Minha conta'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'configuracoes',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Configurações'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'sair',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Terminar sessão',
                  style: TextStyle(color: Colors.red),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: Color(0xFFD5E5F5),
        ),
      ),
    );
  }

  Widget _construirCorpo() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _carregarDados,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _construirCabecalho(),
          const SizedBox(height: 24),
          _construirResumo(),
          const SizedBox(height: 24),
          _construirCartaoEstatisticas(),
          const SizedBox(height: 24),
          _construirSecaoPublicacoes(),
          const SizedBox(height: 24),
          _construirSecaoPendentes(),
          const SizedBox(height: 24),
          _construirSecaoHistorico(),
          const SizedBox(height: 24),
          _construirCartaoConfiguracoes(),
        ],
      ),
    );
  }

  Widget _construirCabecalho() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5E5F5),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEAF4FF),
            child: Icon(
              Icons.person_outline,
              size: 34,
              color: Color(0xFF245A91),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo à tua conta',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _nomeUtilizador(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _supabase.auth.currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirResumo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colunas = constraints.maxWidth >= 700 ? 3 : 1;

        return GridView.count(
          crossAxisCount: colunas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: colunas == 1 ? 4.0 : 2.0,
          children: [
            _cartaoResumo(
              titulo: 'Minhas publicações',
              valor: _obras.length.toString(),
              icone: Icons.menu_book_outlined,
            ),
            _cartaoResumo(
              titulo: 'Obras pendentes',
              valor: _obrasPendentes.length.toString(),
              icone: Icons.hourglass_empty,
            ),
            _cartaoResumo(
              titulo: 'Histórico recente',
              valor: _historico.length.toString(),
              icone: Icons.history,
            ),
          ],
        );
      },
    );
  }

  Widget _cartaoResumo({
    required String titulo,
    required String valor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD5E5F5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icone,
            size: 30,
            color: const Color(0xFF245A91),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCartaoEstatisticas() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF17365D),
            Color(0xFF2868A6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 38,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Estatísticas das minhas obras',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consulta as visualizações das tuas obras, os cliques '
                'nos documentos PDF e as referências bibliográficas '
                'registadas na plataforma.',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Resumo das citações registadas.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.format_quote,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Citações registadas nas tuas obras',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (_carregandoCitacoes)
                        const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Text(
                          _erroCitacoes == null
                              ? _totalCitacoes.toString()
                              : 'Indisponível',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar citações',
                  onPressed: _carregandoCitacoes
                      ? null
                      : _carregarCitacoes,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (_erroCitacoes != null) ...[
            const SizedBox(height: 10),
            Text(
              _erroCitacoes!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],

          if (_citacoesPorObra.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Citações por obra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._obras
                .where((obra) {
              final id = obra['id']?.toString();
              return id != null &&
                  (_citacoesPorObra[id] ?? 0) > 0;
            })
                .map((obra) {
              final id = obra['id'].toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _texto(obra['titulo']),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_citacoesPorObra[id] ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _abrirEstatisticas,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF17365D),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.bar_chart),
              label: const Text('Ver estatísticas completas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSecaoPublicacoes() {
    return _construirSecao(
      titulo: 'Minhas publicações',
      icone: Icons.menu_book_outlined,
      acao: TextButton.icon(
        onPressed: () => context.push('/publicar-opcoes'),
        icon: const Icon(Icons.add),
        label: const Text('Publicar obra'),
      ),
      conteudo: _obras.isEmpty
          ? _mensagemVazia(
        'Ainda não tens obras publicadas.',
        'Podes começar por publicar a tua primeira obra.',
        Icons.library_books_outlined,
        botao: FilledButton.icon(
          onPressed: () => context.push('/publicar-opcoes'),
          icon: const Icon(Icons.add),
          label: const Text('Publicar obra'),
        ),
      )
          : Column(
        children: _obras.map((obra) {
          return _cartaoObra(
            titulo: _texto(obra['titulo']),
            subtitulo:
            '${_texto(obra['autor'])} • '
                '${_texto(obra['categoria'])}',
            onTap: () => _abrirObra(obra['id']),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirSecaoPendentes() {
    return _construirSecao(
      titulo: 'Obras pendentes',
      icone: Icons.hourglass_empty,
      conteudo: _obrasPendentes.isEmpty
          ? _mensagemVazia(
        'Não tens obras pendentes de análise.',
        'As obras submetidas para análise aparecerão aqui.',
        Icons.check_circle_outline,
      )
          : Column(
        children: _obrasPendentes.map((obra) {
          return _cartaoObra(
            titulo: _texto(obra['titulo']),
            subtitulo: 'A aguardar análise',
            onTap: () {
              final id = obra['id'];
              if (id != null) {
                context.push('/obra/$id');
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _construirSecaoHistorico() {
    return _construirSecao(
      titulo: 'Histórico recente',
      icone: Icons.history,
      conteudo: _historico.isEmpty
          ? _mensagemVazia(
        'O teu histórico está vazio.',
        'As obras consultadas poderão aparecer aqui.',
        Icons.history,
      )
          : Column(
        children: _historico.map((item) {
          return _cartaoObra(
            titulo: _texto(
              item['titulo'],
              alternativa: 'Obra consultada',
            ),
            subtitulo: 'Obra consultada recentemente',
            onTap: () => _abrirObra(item['obra_id']),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirCartaoConfiguracoes() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFD5E5F5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF4FF),
          child: Icon(
            Icons.settings_outlined,
            color: Color(0xFF245A91),
          ),
        ),
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Gerir as definições da tua conta.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _abrirConfiguracoes,
      ),
    );
  }

  Widget _construirSecao({
    required String titulo,
    required IconData icone,
    required Widget conteudo,
    Widget? acao,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5E5F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icone,
                color: const Color(0xFF245A91),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17365D),
                  ),
                ),
              ),
              if (acao != null) acao,
            ],
          ),
          const SizedBox(height: 16),
          conteudo,
        ],
      ),
    );
  }

  Widget _cartaoObra({
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFF8FBFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE1EBF5),
        ),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF4FF),
          child: Icon(
            Icons.description_outlined,
            color: Color(0xFF245A91),
          ),
        ),
        title: Text(
          titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitulo),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _mensagemVazia(
      String titulo,
      String descricao,
      IconData icone, {
        Widget? botao,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          children: [
            Icon(
              icone,
              size: 38,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            if (botao != null) ...[
              const SizedBox(height: 14),
              botao,
            ],
          ],
        ),
      ),
    );
  }
}

