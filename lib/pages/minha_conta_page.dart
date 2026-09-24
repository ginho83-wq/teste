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

  bool _dadosUtilizadorAberto = false;

  bool _publicacoesAberto = false;

  bool _solicitacoesAberto = false;

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

    if (!mounted) return;

    await _carregarHistorico();
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icone,
              size: 22,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
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

  Widget _contador(int valor) {
    if (valor <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 26,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        valor.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _itemMenu({
    required IconData icone,
    required String titulo,
    required int contador,
    required bool aberto,
    required VoidCallback onTap,
  }) {
    final tema = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: aberto
            ? tema.colorScheme.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 3,
        ),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: aberto
                ? tema.colorScheme.primary.withValues(alpha: 0.12)
                : tema.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icone,
            size: 21,
            color: aberto
                ? tema.colorScheme.primary
                : tema.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: aberto ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _contador(contador),
            if (contador > 0) const SizedBox(width: 6),
            Icon(
              aberto
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _submenuItem({
    required IconData icone,
    required String titulo,
    required VoidCallback onTap,
  }) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 30,
        right: 4,
        bottom: 3,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icone,
          size: 19,
          color: tema.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _dadosUtilizador() {
    final nome =
    (_perfil?['nome'] ?? _perfil?['name'] ?? 'Utilizador').toString();

    final email =
    (_perfil?['email'] ?? _supabase.auth.currentUser?.email ?? '')
        .toString();

    final inicial =
    nome.trim().isNotEmpty ? nome.trim()[0].toUpperCase() : 'U';

    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 12,
        right: 4,
        bottom: 12,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tema.colorScheme.primary.withValues(alpha: 0.10),
              tema.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tema.colorScheme.primary.withValues(alpha: 0.10),
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: tema.colorScheme.primary,
              child: Text(
                inicial,
                style: TextStyle(
                  color: tema.colorScheme.onPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nome,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 15,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      email,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _painelLateral({
    double? largura,
  }) {
    final tema = Theme.of(context);

    return Container(
      width: largura ?? double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(
        18,
        24,
        14,
        20,
      ),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tema.dividerColor.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tema.colorScheme.primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: tema.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minha conta',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Perfil e publicações',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _itemMenu(
            icone: Icons.person_outline_rounded,
            titulo: 'Dados do utilizador',
            contador: 0,
            aberto: _dadosUtilizadorAberto,
            onTap: () {
              setState(() {
                _dadosUtilizadorAberto = !_dadosUtilizadorAberto;

                if (_dadosUtilizadorAberto) {
                  _publicacoesAberto = false;
                  _solicitacoesAberto = false;
                }
              });
            },
          ),
          if (_dadosUtilizadorAberto) _dadosUtilizador(),
          const SizedBox(height: 4),
          _itemMenu(
            icone: Icons.library_books_outlined,
            titulo: 'Minhas publicações',
            contador: _minhasObras.length,
            aberto: _publicacoesAberto,
            onTap: () {
              setState(() {
                _publicacoesAberto = !_publicacoesAberto;

                if (_publicacoesAberto) {
                  _dadosUtilizadorAberto = false;
                  _solicitacoesAberto = false;
                }
              });
            },
          ),
          if (_publicacoesAberto)
            _submenuItem(
              icone: Icons.description_outlined,
              titulo: 'Todas as publicações',
              onTap: () {},
            ),
          const SizedBox(height: 4),
          _itemMenu(
            icone: Icons.delete_outline_rounded,
            titulo: 'Solicitações de remoção',
            contador: _solicitacoes.length,
            aberto: _solicitacoesAberto,
            onTap: () {
              setState(() {
                _solicitacoesAberto = !_solicitacoesAberto;

                if (_solicitacoesAberto) {
                  _dadosUtilizadorAberto = false;
                  _publicacoesAberto = false;
                }
              });
            },
          ),
          if (_solicitacoesAberto)
            _submenuItem(
              icone: Icons.pending_actions_outlined,
              titulo: 'Minhas solicitações',
              onTap: () {},
            ),
        ],
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
        final titulo =
        (dados['titulo'] ?? 'Sem título').toString();

        final autor = (dados['autor'] ?? '').toString();

        final categoria =
        (dados['categoria'] ?? '').toString();

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
        Icons.history_rounded,
      );
    }

    return Column(
      children: _historico.map((item) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.7),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              item.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: item.dataConsulta != null
                ? Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Consultada em ${_formatarData(item.dataConsulta)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
                : null,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
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
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: tema.dividerColor.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tema.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icone,
              size: 30,
              color: tema.colorScheme.primary.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tema.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardPublicacoes() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _tituloSecao(
            'Minhas publicações (${_minhasObras.length})',
            icone: Icons.library_books_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'Todas as obras publicadas por si.',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          _listaObras(),
        ],
      ),
    );
  }

  Widget _cardHistorico() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _tituloSecao(
            'Obras consultadas recentemente (${_historico.length})',
            icone: Icons.history_rounded,
            trailing: TextButton.icon(
              onPressed: _abrirHistorico,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
              ),
              label: const Text('Ver tudo'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aceda rapidamente às últimas obras que consultou.',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          _listaHistorico(),
        ],
      ),
    );
  }

  Widget _conteudoPrincipalMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardPublicacoes(),
        _cardHistorico(),
      ],
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // MOBILE / TABLET
          if (constraints.maxWidth < 850) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _painelLateral(),
                  _cardPublicacoes(),
                  _cardHistorico(),
                ],
              ),
            );
          }

          // DESKTOP
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  // ALTERADO:
                  // os dois cards passam a ter a mesma altura.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _painelLateral(
                      largura: 310,
                    ),
                    Expanded(
                      child: _cardPublicacoes(),
                    ),
                  ],
                ),

                // Histórico ocupa toda a largura.
                _cardHistorico(),
              ],
            ),
          );
        },
      ),
    );
  }
}

