import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../repositories/comentarios_repository.dart';
import '../repositories/obras_pendentes_repository.dart';
import '../repositories/obras_repository.dart';
import '../repositories/solicitacoes_remocao_repository.dart';
import '../services/auth_service.dart';
import '../services/historico_obras_service.dart';
import '../widgets/avatar_utilizador.dart';
import '../widgets/obra_lista_item.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService.instancia;

  final _obrasRepository = ObrasRepository.instancia;
  final _obrasPendentesRepository =
      ObrasPendentesRepository.instancia;
  final _comentariosRepository =
      ComentariosRepository.instancia;
  final _solicitacoesRepository =
      SolicitacoesRemocaoRepository.instancia;
  final _historicoService =
      HistoricoObrasService.instancia;

  Map<String, dynamic>? _perfil;

  List<Obra> _minhasObras = [];
  List<ObraPendente> _minhasObrasPendentes = [];
  List<Map<String, dynamic>> _comentarios = [];
  List<Map<String, dynamic>> _solicitacoes = [];
  List<HistoricoObra> _historico = [];

  bool _carregando = true;
  String? _erro;

  bool _ehAdmin = false;
  bool _carregandoPerfil = false;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription = _authService.eventosAuth.listen(
      _tratarAlteracaoAutenticacao,
    );

    _carregarDados();
    _verificarAdministrador();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _tratarAlteracaoAutenticacao(
      AuthState estado,
      ) async {
    if (!mounted) return;

    if (estado.session == null) {
      setState(() {
        _ehAdmin = false;
        _carregandoPerfil = false;
      });
      return;
    }

    setState(() {
      _carregandoPerfil = true;
    });

    await _verificarAdministrador();
    await _carregarDados();

    if (mounted) {
      setState(() {
        _carregandoPerfil = false;
      });
    }
  }

  Future<void> _verificarAdministrador() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      if (mounted) {
        setState(() {
          _ehAdmin = false;
        });
      }
      return;
    }

    try {
      final admin = await _authService.ehAdmin();

      if (!mounted) return;

      setState(() {
        _ehAdmin = admin;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
      });
    }
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final usuario = _supabase.auth.currentUser;

      if (usuario == null) {
        throw Exception('Utilizador não autenticado.');
      }

      final perfil = await _supabase
          .from('profiles')
          .select()
          .eq('id', usuario.id)
          .maybeSingle();

      final minhasObras =
      await _obterMinhasObras(usuario.id);

      List<ObraPendente> minhasObrasPendentes = [];

      try {
        minhasObrasPendentes =
        await _obrasPendentesRepository.carregarDoUsuario(
          usuario.id,
        );
      } catch (_) {
        minhasObrasPendentes = [];
      }

      final comentarios =
      await _comentariosRepository
          .obterComentariosDasMinhasObras(
        usuario.id,
      );

      final solicitacoes =
      await _solicitacoesRepository.obterMinhasSolicitacoes();

      final historico =
      await _historicoService.obterConsultasRecentes(
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _minhasObras = minhasObras;
        _minhasObrasPendentes = minhasObrasPendentes;
        _comentarios = comentarios;
        _solicitacoes = solicitacoes;
        _historico = historico;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  Future<List<Obra>> _obterMinhasObras(
      String userId,
      ) async {
    final resposta = await _supabase
        .from('obras')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (resposta as List)
        .map(
          (item) => Obra.fromMap(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList();
  }

  // ============================================================
  // ABRIR OBRA PUBLICADA
  // ============================================================

  Future<void> _abrirObra(Obra obra) async {
    if (!mounted) return;

    await context.push('/obra/${obra.id}');
  }

  // ============================================================
  // DETALHES DA OBRA PENDENTE
  // ============================================================

  Future<void> _abrirDetalhesObraPendente(
      ObraPendente obra,
      ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12,
          ),
          title: Text(
            obra.titulo,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Divider(height: 20),
                _linhaDetalhePendente(
                  dialogContext,
                  'Autor',
                  obra.autor,
                ),
                _linhaDetalhePendente(
                  dialogContext,
                  'Categoria',
                  obra.categoria,
                ),
                _linhaDetalhePendente(
                  dialogContext,
                  'Data de envio',
                  _formatarData(obra.createdAt),
                ),
                const SizedBox(height: 4),
                _linhaEstadoPendente(dialogContext),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF2D59C),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 21,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Esta obra foi enviada e está pendente de aprovação.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _linhaDetalhePendente(
      BuildContext context,
      String titulo,
      String? valor,
      ) {
    if (valor == null || valor.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaEstadoPendente(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Estado',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1D6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty,
                size: 17,
                color: Colors.orange,
              ),
              SizedBox(width: 7),
              Text(
                'Pendente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SOLICITAR REMOÇÃO
  // ============================================================

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
              hintText:
              'Explique o motivo da solicitação...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final texto =
                controlador.text.trim();

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

      _mostrarMensagem(
        'Solicitação de remoção enviada.',
      );

      await _carregarDados();
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível enviar a solicitação.',
        erro: true,
      );
    }
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  Future<void> _abrirHistorico() async {
    await context.push('/historico-obras');

    if (!mounted) return;

    await _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    try {
      final historico =
      await _historicoService.obterConsultasRecentes(
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _historico = historico;
      });
    } catch (_) {}
  }

  Future<void> _removerConsulta(
      HistoricoObra item,
      ) async {
    try {
      await _historicoService.removerConsulta(
        id: item.id,
      );

      if (!mounted) return;

      setState(() {
        _historico.removeWhere(
              (historico) => historico.id == item.id,
        );
      });

      _mostrarMensagem(
        'Consulta removida do histórico.',
      );
    } catch (_) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível remover a consulta.',
        erro: true,
      );
    }
  }

  Future<void> _limparHistorico() async {
    if (_historico.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Limpar histórico'),
          content: const Text(
            'Tem a certeza de que deseja remover todo o histórico de obras consultadas?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _historicoService.limparHistorico();

      if (!mounted) return;

      setState(() {
        _historico.clear();
      });

      _mostrarMensagem(
        'Histórico limpo com sucesso.',
      );
    } catch (_) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível limpar o histórico.',
        erro: true,
      );
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) {
      return '—';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return '$dia/$mes/$ano';
  }

  // ============================================================
  // TÍTULO DE SECÇÃO
  // ============================================================

  Widget _tituloSecao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        bottom: 12,
      ),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tituloSecaoHistorico() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        bottom: 12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Histórico recente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_historico.isNotEmpty)
            TextButton(
              onPressed: _limparHistorico,
              child: const Text('Limpar histórico'),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CARTÃO DE OBRA PUBLICADA
  // ============================================================

  Widget _cartaoObraPublicada(Obra obra) {
    final mobile =
        MediaQuery.sizeOf(context).width < 600;

    return ObraListaItem(
      obra: obra,
      mobile: mobile,
      onTap: () => _abrirObra(obra),
    );
  }

  // ============================================================
  // CARTÃO DE OBRA PENDENTE
  // ============================================================

  Widget _cartaoObraPendente(
      ObraPendente obra,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.hourglass_empty,
            color: Colors.orange,
          ),
        ),
        title: Text(
          obra.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (obra.autor.trim().isNotEmpty)
              Text(obra.autor),
            if (obra.categoria.trim().isNotEmpty)
              Text(obra.categoria),
            Text(
              'Enviada em ${_formatarData(obra.createdAt)}',
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Ver detalhes',
          icon: const Icon(Icons.more_vert),
          onPressed: () =>
              _abrirDetalhesObraPendente(obra),
        ),
        onTap: () =>
            _abrirDetalhesObraPendente(obra),
      ),
    );
  }

  // ============================================================
  // LISTA DE OBRAS
  // ============================================================

  Widget _listaObras() {
    if (_minhasObras.isEmpty &&
        _minhasObrasPendentes.isEmpty) {
      return _caixaVazia(
        'Ainda não publicou nenhuma obra.',
        Icons.menu_book_outlined,
      );
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        if (_minhasObrasPendentes.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(
              left: 2,
              bottom: 10,
            ),
            child: Text(
              'Publicações pendentes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._minhasObrasPendentes.map(
            _cartaoObraPendente,
          ),
          if (_minhasObras.isNotEmpty)
            const SizedBox(height: 18),
        ],
        if (_minhasObras.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(
              left: 2,
              bottom: 10,
            ),
            child: Text(
              'Publicações aprovadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._minhasObras.map(
            _cartaoObraPublicada,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // COMENTÁRIOS
  // ============================================================

  Widget _listaComentarios() {
    if (_comentarios.isEmpty) {
      return _caixaVazia(
        'Ainda não existem comentários nas suas obras.',
        Icons.comment_outlined,
      );
    }

    return Column(
      children:
      _comentarios.map((comentario) {
        final obraDados = comentario['obras'];

        final tituloObra = obraDados is Map
            ? (obraDados['titulo']?.toString() ??
            'Obra')
            : 'Obra';

        final obraId =
        comentario['obra_id']?.toString();

        final texto =
            comentario['comentario']?.toString() ??
                comentario['texto']?.toString() ??
                '';

        final data =
        comentario['created_at']?.toString();

        return Card(
          margin:
          const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.comment_outlined),
            ),
            title: Text(
              tituloObra,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                if (texto.isNotEmpty)
                  Text(texto),
                if (data != null)
                  Text(
                    _formatarData(
                      DateTime.tryParse(data),
                    ),
                  ),
              ],
            ),
            onTap: obraId == null
                ? null
                : () async {
              try {
                final dados = await _supabase
                    .from('obras')
                    .select()
                    .eq('id', obraId)
                    .maybeSingle();

                if (dados == null ||
                    !mounted) {
                  return;
                }

                final obra = Obra.fromMap(
                  Map<String, dynamic>.from(
                    dados,
                  ),
                );

                await _abrirObra(obra);
              } catch (_) {}
            },
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  Widget _listaHistorico() {
    if (_historico.isEmpty) {
      return _caixaVazia(
        'Ainda não existem consultas recentes.',
        Icons.history,
      );
    }

    return Column(
      children: _historico.map((item) {
        return Card(
          margin:
          const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.history),
            ),
            title: Text(
              item.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatarData(item.createdAt),
            ),
            trailing: IconButton(
              tooltip: 'Remover do histórico',
              icon: const Icon(Icons.close),
              onPressed: () =>
                  _removerConsulta(item),
            ),
            onTap: () {
              context.push(
                '/obra/${item.obraId}',
              );
            },
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // SOLICITAÇÕES DE REMOÇÃO
  // ============================================================

  Widget _listaSolicitacoes() {
    if (_solicitacoes.isEmpty) {
      return _caixaVazia(
        'Ainda não existem solicitações de remoção.',
        Icons.delete_outline,
      );
    }

    return Column(
      children:
      _solicitacoes.map((solicitacao) {
        final obraDados =
        solicitacao['obras'];

        final tituloObra = obraDados is Map
            ? (obraDados['titulo']?.toString() ??
            'Obra')
            : 'Obra';

        final motivo =
            solicitacao['motivo']?.toString() ??
                '';

        final status =
            solicitacao['status']?.toString() ??
                '';

        final data =
        solicitacao['created_at']?.toString();

        return Card(
          margin:
          const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.delete_outline),
            ),
            title: Text(
              tituloObra,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                if (status.isNotEmpty)
                  Text(
                    _formatarStatusSolicitacao(
                      status,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (motivo.isNotEmpty)
                  Text(motivo),
                if (data != null)
                  Text(
                    _formatarData(
                      DateTime.tryParse(data),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatarStatusSolicitacao(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return 'Pendente';

      case 'aprovada':
        return 'Aprovada';

      case 'rejeitada':
        return 'Rejeitada';

      case 'concluida':
        return 'Concluída';

      default:
        return status;
    }
  }

  // ============================================================
  // CAIXA VAZIA
  // ============================================================

  Widget _caixaVazia(
      String mensagem,
      IconData icone,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFDDE7F0),
        ),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            size: 34,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    final estaAutenticado =
        _supabase.auth.currentUser != null;

    return AppBar(
      backgroundColor:
      const Color(0xFFEAF4FF),
      elevation: 0,
      surfaceTintColor:
      const Color(0xFFEAF4FF),
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      titleSpacing: 28,
      title: const Text(
        'Minha Conta',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        if (estaAutenticado)
          Padding(
            padding:
            const EdgeInsets.only(right: 20),
            child: PopupMenuButton<String>(
              tooltip: 'Conta',
              offset: const Offset(0, 48),
              onSelected: (valor) {
                switch (valor) {
                  case 'conta':
                    _abrirConta();
                    break;

                  case 'configuracoes':
                    context.go('/minha-conta');
                    break;

                  case 'sair':
                    _sair();
                    break;
                }
              },
              itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    value: 'conta',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _ehAdmin
                              ? 'Administração'
                              : 'Minha conta',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'configuracoes',
                    child: Row(
                      children: [
                        Icon(
                          Icons.manage_accounts_outlined,
                        ),
                        SizedBox(width: 10),
                        Text('Minha conta'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'sair',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 10),
                        Text('Sair'),
                      ],
                    ),
                  ),
                ];
              },
              child: const AvatarUtilizador(
                radius: 20,
              ),
            ),
          ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD5E5F5),
        ),
      ),
    );
  }

  // ============================================================
  // SAIR
  // ============================================================

  Future<void> _sair() async {
    try {
      await _authService.sair();

      if (!mounted) return;

      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível terminar a sessão.',
        erro: true,
      );
    }
  }

  // ============================================================
  // CONTA / ADMINISTRAÇÃO
  // ============================================================

  void _abrirConta() {
    if (_ehAdmin) {
      context.go('/admin-obras');
    } else {
      context.go('/minha-conta');
    }
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(
      String mensagem, {
        bool erro = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor:
          erro ? Colors.red : null,
        ),
      );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _conteudo() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            40,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _tituloSecao(
                'Minhas publicações',
              ),

              _listaObras(),

              const SizedBox(height: 32),

              _tituloSecao(
                'Comentários',
              ),

              _listaComentarios(),

              const SizedBox(height: 32),

              _tituloSecao(
                'Solicitações de remoção',
              ),

              _listaSolicitacoes(),

              const SizedBox(height: 32),

              _tituloSecaoHistorico(),

              _listaHistorico(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFCFCFC),
      appBar: _buildAppBar(),
      body: _carregando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _erro != null
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _erro!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:
                _carregarDados,
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
      )
          : RefreshIndicator(
        onRefresh: _carregarDados,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: _conteudo(),
        ),
      ),
    );
  }
}

