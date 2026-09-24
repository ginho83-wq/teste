import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../repositories/solicitacoes_remocao_repository.dart';
import '../services/historico_obras_service.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final ObrasRepository _obrasRepository = ObrasRepository.instancia;

  final SolicitacoesRemocaoRepository _solicitacoesRepository =
      SolicitacoesRemocaoRepository.instancia;

  final HistoricoObrasService _historicoService =
      HistoricoObrasService.instancia;

  Map<String, dynamic>? _perfil;

  List<Map<String, dynamic>> _minhasObras = [];

  List<Map<String, dynamic>> _solicitacoes = [];

  List<HistoricoObra> _historico = [];

  bool _carregando = true;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final usuario = _supabase.auth.currentUser;

      if (usuario == null) {
        throw Exception('Utilizador não autenticado.');
      }

      final perfilResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', usuario.id)
          .maybeSingle();

      final minhasObras = await _obterMinhasObras(usuario.id);

      List<Map<String, dynamic>> solicitacoes = [];

      try {
        solicitacoes =
        await _solicitacoesRepository.obterMinhasSolicitacoes();
      } catch (_) {
        solicitacoes = [];
      }

      List<HistoricoObra> historico = [];

      try {
        historico =
        await _historicoService.obterConsultasRecentes(limite: 5);
      } catch (_) {
        historico = [];
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfilResponse;
        _minhasObras = minhasObras;
        _solicitacoes = solicitacoes;
        _historico = historico;
        _carregando = false;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _obterMinhasObras(
      String userId,
      ) async {
    final response = await _supabase
        .from('obras')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _abrirDetalhesObra(Obra obra) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(obra.titulo),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (obra.autor.trim().isNotEmpty) ...[
                  const Text(
                    'Autor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(obra.autor),
                  const SizedBox(height: 16),
                ],
                if (obra.categoria.trim().isNotEmpty) ...[
                  const Text(
                    'Categoria',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(obra.categoria),
                  const SizedBox(height: 16),
                ],
                if (obra.anoObra != null) ...[
                  const Text(
                    'Ano',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(obra.anoObra.toString()),
                  const SizedBox(height: 16),
                ],
                if (obra.descricao != null &&
                    obra.descricao!.trim().isNotEmpty) ...[
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(obra.descricao!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            if (obra.urlDocumento.trim().isNotEmpty)
              FilledButton.icon(
                onPressed: () async {
                  final url = Uri.tryParse(obra.urlDocumento);

                  if (url == null) return;

                  final aberto = await launchUrl(
                    url,
                    webOnlyWindowName: '_blank',
                  );

                  if (!aberto && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Não foi possível abrir o documento.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir obra'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _solicitarRemocao(Obra obra) async {
    final controlador = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solicitar remoção'),
          content: TextField(
            controller: controlador,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              hintText: 'Explique o motivo da solicitação...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final texto = controlador.text.trim();

                if (texto.isEmpty) {
                  return;
                }

                Navigator.of(context).pop(texto);
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    controlador.dispose();

    if (motivo == null || motivo.trim().isEmpty) {
      return;
    }

    try {
      await _solicitacoesRepository.criarSolicitacao(
        obraId: obra.id,
        motivo: motivo.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitação de remoção enviada com sucesso.',
          ),
        ),
      );

      await _carregarDados();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao enviar solicitação: $e',
          ),
        ),
      );
    }
  }

  Future<void> _abrirHistorico() async {
    await context.push('/historico-obras');
  }

  Future<void> _carregarHistorico() async {
    try {
      final historico =
      await _historicoService.obterConsultasRecentes(limite: 5);

      if (!mounted) return;

      setState(() {
        _historico = historico;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _historico = [];
      });
    }
  }

  String _formatarData(dynamic valor) {
    if (valor == null) {
      return '';
    }

    try {
      final data = DateTime.parse(valor.toString()).toLocal();

      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final ano = data.year.toString();

      return '$dia/$mes/$ano';
    } catch (_) {
      return valor.toString();
    }
  }

  Widget _tituloSecao(
      String titulo, {
        IconData? icone,
        Widget? trailing,
      }) {
    return Row(
      children: [
        if (icone != null) ...[
          Icon(
            icone,
            size: 22,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _cartaoPerfil() {
    final nome =
    (_perfil?['nome'] ?? _perfil?['name'] ?? 'Utilizador').toString();

    final email =
    (_perfil?['email'] ?? _supabase.auth.currentUser?.email ?? '')
        .toString();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(
                nome.isNotEmpty ? nome[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaObras() {
    if (_minhasObras.isEmpty) {
      return _caixaVazia(
        'Ainda não publicou nenhuma obra.',
        Icons.library_books_outlined,
      );
    }

    return Column(
      children: _minhasObras.map((dados) {
        final titulo = (dados['titulo'] ?? 'Sem título').toString();

        final autor = (dados['autor'] ?? '').toString();

        final categoria = (dados['categoria'] ?? '').toString();

        final dataPublicacao = dados['data_publicacao'];

        final obra = Obra.fromMap(dados);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.description_outlined),
            ),
            title: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (autor.isNotEmpty) Text(autor),
                if (categoria.isNotEmpty) Text(categoria),
                if (dataPublicacao != null)
                  Text(
                    'Publicada em ${_formatarData(dataPublicacao)}',
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (valor) {
                if (valor == 'abrir') {
                  _abrirDetalhesObra(obra);
                } else if (valor == 'remover') {
                  _solicitarRemocao(obra);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'abrir',
                  child: Text('Ver detalhes'),
                ),
                PopupMenuItem(
                  value: 'remover',
                  child: Text('Solicitar remoção'),
                ),
              ],
            ),
            onTap: () => _abrirDetalhesObra(obra),
          ),
        );
      }).toList(),
    );
  }

  Widget _listaHistorico() {
    if (_historico.isEmpty) {
      return _caixaVazia(
        'Ainda não existem obras consultadas recentemente.',
        Icons.history,
      );
    }

    return Column(
      children: _historico.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.history),
            ),
            title: Text(
              item.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: item.dataConsulta != null
                ? Text(
              'Consultada em ${_formatarData(item.dataConsulta)}',
            )
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final obraId = item.obraId;

              if (obraId == null || obraId.isEmpty) {
                return;
              }

              try {
                final obra =
                await _obrasRepository.carregarPorId(obraId);

                if (obra == null || !mounted) {
                  return;
                }

                await _abrirDetalhesObra(obra);
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Não foi possível abrir a obra: $e',
                    ),
                  ),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _listaSolicitacoes() {
    if (_solicitacoes.isEmpty) {
      return _caixaVazia(
        'Não existem solicitações de remoção.',
        Icons.delete_outline,
      );
    }

    return Column(
      children: _solicitacoes.map((solicitacao) {
        final status =
        (solicitacao['status'] ?? 'pendente').toString();

        final motivo =
        (solicitacao['motivo'] ?? '').toString();

        final titulo =
        (solicitacao['obra_titulo'] ??
            solicitacao['titulo'] ??
            'Obra')
            .toString();

        final statusFormatado = status.isEmpty
            ? 'Pendente'
            : '${status[0].toUpperCase()}${status.substring(1)}';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(
              status == 'aprovada'
                  ? Icons.check_circle_outline
                  : status == 'rejeitada'
                  ? Icons.cancel_outlined
                  : Icons.hourglass_empty,
            ),
            title: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (motivo.isNotEmpty) Text(motivo),
                const SizedBox(height: 4),
                Text(
                  'Estado: $statusFormatado',
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _caixaVazia(
      String texto,
      IconData icone,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            size: 40,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    return RefreshIndicator(
      onRefresh: () async {
        await _carregarDados();
        await _carregarHistorico();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _cartaoPerfil(),

          const SizedBox(height: 24),

          _tituloSecao(
            'Minhas publicações',
            icone: Icons.library_books_outlined,
          ),

          const SizedBox(height: 12),

          _listaObras(),

          const SizedBox(height: 28),

          _tituloSecao(
            'Solicitações de remoção',
            icone: Icons.delete_outline,
          ),

          const SizedBox(height: 12),

          _listaSolicitacoes(),

          const SizedBox(height: 28),

          _tituloSecao(
            'Histórico',
            icone: Icons.history,
            trailing: TextButton(
              onPressed: _abrirHistorico,
              child: const Text('Ver tudo'),
            ),
          ),

          const SizedBox(height: 12),

          _listaHistorico(),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _supabase.auth.signOut();

                if (!mounted) return;

                context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Minha conta'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _carregarDados,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha conta'),
      ),
      body: _conteudo(),
    );
  }
}

