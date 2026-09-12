import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import '../repositories/obras_repository.dart';
import '../services/auth_service.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({
    super.key,
  });

  @override
  State<MinhaContaPage> createState() =>
      _MinhaContaPageState();
}

class _MinhaContaPageState
    extends State<MinhaContaPage> {
  final AuthService _auth =
      AuthService.instancia;

  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  final ObrasPendentesRepository
  _pendentesRepository =
      ObrasPendentesRepository.instancia;

  List<Obra> _publicadas = [];
  List<ObraPendente> _pendentes = [];

  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = 'É necessário iniciar sessão.';
      });

      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final publicadas =
      await _obrasRepository.carregarMinhasObras(
        usuario.id,
      );

      final pendentes =
      await _pendentesRepository.carregarDoUsuario(
        usuario.id,
      );

      if (!mounted) return;

      setState(() {
        _publicadas = publicadas;
        _pendentes = pendentes;
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

  String _mensagemErro(Object erro) {
    final texto = erro.toString();

    if (texto.startsWith('Exception: ')) {
      return texto.substring(11);
    }

    return texto;
  }

  String _nomeUtilizador() {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      return 'Utilizador';
    }

    final metadata = usuario.userMetadata ?? {};

    final nome =
        metadata['nome'] ??
            metadata['full_name'] ??
            metadata['name'];

    if (nome is String &&
        nome.trim().isNotEmpty) {
      return nome.trim();
    }

    return usuario.email?.split('@').first ??
        'Utilizador';
  }

  String _emailUtilizador() {
    return Supabase.instance.client.auth.currentUser
        ?.email ??
        '';
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return '—';
    }

    final local = data.toLocal();

    final dia =
    local.day.toString().padLeft(2, '0');
    final mes =
    local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  Future<void> _sair() async {
    try {
      await _auth.sair();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mensagemErro(e),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha conta'),
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

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _carregar,
                child:
                const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPerfil(),

          const SizedBox(height: 20),

          // ====================================================
          // HISTÓRICO DE OBRAS
          // ====================================================

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.history,
              ),
              title: const Text(
                'Histórico de obras',
              ),
              subtitle: const Text(
                'Consultar as obras que você consultou',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                context.go('/historico-obras');
              },
            ),
          ),

          const SizedBox(height: 32),

          _buildPublicadas(),

          const SizedBox(height: 32),

          _buildPendentes(),

          const SizedBox(height: 32),

          OutlinedButton(
            onPressed: _sair,
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfil() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Dados da conta',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person_outline,
              ),
              title: Text(_nomeUtilizador()),
              subtitle: const Text('Nome'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.email_outlined,
              ),
              title: Text(_emailUtilizador()),
              subtitle: const Text('E-mail'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicadas() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Minhas publicações',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),
        const SizedBox(height: 12),
        if (_publicadas.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Você ainda não possui obras publicadas.',
              ),
            ),
          )
        else
          ..._publicadas.map(
                (obra) => Card(
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                ),
                title: Text(obra.titulo),
                subtitle: Text(
                  '${obra.categoria} • '
                      '${_formatarData(obra.dataPublicacao)}',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPendentes() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Em análise',
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),
        const SizedBox(height: 12),
        if (_pendentes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Não existem publicações em análise.',
              ),
            ),
          )
        else
          ..._pendentes.map(
                (obra) => Card(
              margin: const EdgeInsets.only(
                bottom: 12,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.hourglass_empty,
                ),
                title: Text(obra.titulo),
                subtitle: Text(
                  '${obra.categoria} • '
                      '${_formatarData(obra.dataPublicacao)}',
                ),
                trailing: const Chip(
                  label: Text('Pendente'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

