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
  final SupabaseClient _supabase = Supabase.instance.client;

  final AuthService _authService = AuthService.instancia;

  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  final ObrasPendentesRepository _obrasPendentesRepository =
      ObrasPendentesRepository.instancia;

  final ComentariosRepository _comentariosRepository =
      ComentariosRepository.instancia;

  final SolicitacoesRemocaoRepository _solicitacoesRepository =
      SolicitacoesRemocaoRepository.instancia;

  final HistoricoObrasService _historicoService =
      HistoricoObrasService.instancia;

  Map<String, dynamic>? _perfil;

  List<Map<String, dynamic>> _minhasObras = [];

  List<ObraPendente> _minhasObrasPendentes = [];

  List<Map<String, dynamic>> _comentarios = [];

  List<Map<String, dynamic>> _solicitacoes = [];

  List<HistoricoObra> _historico = [];

  bool _carregando = true;

  String? _erro;

  bool _ehAdmin = false;

  bool _carregandoPerfil = true;

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

  void _tratarAlteracaoAutenticacao(
      AuthState estado,
      ) {
    if (!mounted) return;

    final autenticado = estado.session != null;

    setState(() {
      if (!autenticado) {
        _ehAdmin = false;
        _carregandoPerfil = false;
      } else {
        _carregandoPerfil = true;
      }
    });

    if (autenticado) {
      _verificarAdministrador();
      _carregarDados();
    }
  }

  Future<void> _verificarAdministrador() async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
        _carregandoPerfil = false;
      });

      return;
    }

    try {
      final ehAdmin = await _authService.ehAdmin();

      if (!mounted) return;

      setState(() {
        _ehAdmin = ehAdmin;
        _carregandoPerfil = false;
      });
    } catch (e) {
      debugPrint(
        'MINHA CONTA: erro ao verificar administrador: $e',
      );

      if (!mounted) return;

      setState(() {
        _ehAdmin = false;
        _carregandoPerfil = false;
      });
    }
  }

  Future<void> _carregarDados() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final usuario = _supabase.auth.currentUser;

      if (usuario == null) {
        throw Exception(
          'Utilizador não autenticado.',
        );
      }

      final perfilResponse = await _supabase
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

      List<Map<String, dynamic>> comentarios = [];

      try {
        comentarios =
        await _comentariosRepository
            .obterComentariosDasMinhasObras(
          usuario.id,
        );
      } catch (_) {
        comentarios = [];
      }

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
        await _historicoService.obterConsultasRecentes(
          limite: 5,
        );
      } catch (_) {
        historico = [];
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfilResponse;
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

  Future<List<Map<String, dynamic>>> _obterMinhasObras(
      String userId,
      ) async {
    final response = await _supabase
        .from('obras')
        .select()
        .eq('user_id', userId)
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  Future<void> _abrirDetalhesObra(
      Obra obra,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            obra.titulo,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _linhaDetalhe(
                  'Autor',
                  obra.autor,
                ),
                _linhaDetalhe(
                  'Categoria',
                  obra.categoria,
                ),
                if (obra.anoObra != null)
                  _linhaDetalhe(
                    'Ano',
                    obra.anoObra.toString(),
                  ),
                _linhaDetalhe(
                  'Estado',
                  'Publicada',
                ),
                if (obra.descricao != null &&
                    obra.descricao!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(obra.descricao!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final url = Uri.tryParse(
                  obra.urlDocumento,
                );

                if (url == null) {
                  return;
                }

                await launchUrl(
                  url,
                  webOnlyWindowName: '_blank',
                );
              },
              icon: const Icon(
                Icons.open_in_new,
              ),
              label: const Text(
                'Abrir obra',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirDetalhesObraPendente(
      ObraPendente obra,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            obra.titulo,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _linhaDetalhe(
                  'Autor',
                  obra.autor,
                ),
                _linhaDetalhe(
                  'Categoria',
                  obra.categoria,
                ),
                if (obra.anoObra != null)
                  _linhaDetalhe(
                    'Ano',
                    obra.anoObra.toString(),
                  ),
                _linhaDetalhe(
                  'Estado',
                  'Pendente',
                ),
                if (obra.descricao != null &&
                    obra.descricao!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(obra.descricao!),
                ],
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 20,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Esta obra está pendente de análise e aprovação. '
                              'Ela será disponibilizada no acervo após a aprovação.',
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
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _linhaDetalhe(
      String titulo,
      String valor,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: RichText(
        text: TextSpan(
          style:
          DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  Future<void> _solicitarRemocao(
      Obra obra,
      ) async {
    final controller = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Solicitar remoção',
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration:
            const InputDecoration(
              labelText: 'Motivo',
              hintText:
              'Indique o motivo da solicitação...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                final texto =
                controller.text.trim();

                if (texto.isEmpty) {
                  return;
                }

                Navigator.of(context)
                    .pop(texto);
              },
              child: const Text(
                'Enviar',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (motivo == null ||
        motivo.trim().isEmpty) {
      return;
    }

    try {
      await _solicitacoesRepository.criarSolicitacao(
        obraId: obra.id,
        motivo: motivo.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitação de remoção enviada com sucesso.',
          ),
        ),
      );

      await _carregarDados();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível enviar a solicitação: $e',
          ),
        ),
      );
    }
  }

  Future<void> _abrirHistorico() async {
    await context.push(
      '/historico-obras',
    );

    if (mounted) {
      await _carregarHistorico();
    }
  }

  Future<void> _carregarHistorico() async {
    try {
      final historico =
      await _historicoService
          .obterConsultasRecentes(
        limite: 5,
      );

      if (!mounted) return;

      setState(() {
        _historico = historico;
      });
    } catch (_) {}
  }

  String _formatarData(dynamic valor) {
    if (valor == null) {
      return '';
    }

    try {
      final data = valor is DateTime
          ? valor
          : DateTime.parse(
        valor.toString(),
      );

      final dia = data.day
          .toString()
          .padLeft(2, '0');

      final mes = data.month
          .toString()
          .padLeft(2, '0');

      final ano = data.year.toString();

      return '$dia/$mes/$ano';
    } catch (_) {
      return valor.toString();
    }
  }

  Widget _tituloSecao(
      String titulo, {
        IconData? icone,
        VoidCallback? onVerTodos,
      }) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 12,
      ),
      child: Row(
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
          if (onVerTodos != null)
            TextButton(
              onPressed: onVerTodos,
              child: const Text(
                'Ver todos',
              ),
            ),
        ],
      ),
    );
  }

  Widget _cartaoPerfil() {
    final nome =
    (_perfil?['nome'] ?? '')
        .toString()
        .trim();

    final email =
    (_perfil?['email'] ??
        _supabase
            .auth
            .currentUser
            ?.email ??
        '')
        .toString()
        .trim();

    final role =
    (_perfil?['role'] ?? 'user')
        .toString();

    final nomeExibicao =
    nome.isNotEmpty
        ? nome
        : 'Utilizador';

    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          children: [
            AvatarUtilizador(
              radius: 30,
              perfil: _perfil,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeExibicao,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        top: 3,
                      ),
                      child: Text(
                        email,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),
                  if (role.isNotEmpty)
                    Padding(
                      padding:
                      const EdgeInsets.only(
                        top: 5,
                      ),
                      child: Text(
                        role == 'admin'
                            ? 'Administrador'
                            : 'Utilizador',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors
                              .grey
                              .shade700,
                        ),
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

  // ===============================================================
  // OBRAS PUBLICADAS
  // ===============================================================

  Widget _cartaoObraPublicada(
      Map<String, dynamic> dados,
      ) {
    final obra =
    Obra.fromMap(dados);

    final mobile =
        MediaQuery.sizeOf(context).width <
            600;

    return ObraListaItem(
      obra: obra,
      mobile: mobile,
      onTap: () =>
          _abrirDetalhesObra(obra),
    );
  }

  Widget _cartaoObraPendente(
      ObraPendente obra,
      ) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          Colors.orange.withValues(
            alpha: 0.12,
          ),
          child: const Icon(
            Icons.hourglass_empty,
            color: Colors.orange,
          ),
        ),
        title: Text(
          obra.titulo,
          maxLines: 2,
          overflow:
          TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (obra.autor.isNotEmpty)
              Text(obra.autor),
            if (obra.categoria.isNotEmpty)
              Text(obra.categoria),
            Text(
              'Submetida em '
                  '${_formatarData(obra.dataPublicacao)}',
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 16,
                  color:
                  Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pendente',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Ver detalhes',
          icon: const Icon(
            Icons.more_vert,
          ),
          onPressed: () {
            _abrirDetalhesObraPendente(
              obra,
            );
          },
        ),
        onTap: () =>
            _abrirDetalhesObraPendente(
              obra,
            ),
      ),
    );
  }

  Widget _listaObras() {
    if (_minhasObras.isEmpty &&
        _minhasObrasPendentes.isEmpty) {
      return _caixaVazia(
        'Ainda não publicou nem submeteu nenhuma obra.',
        Icons.library_books_outlined,
      );
    }

    return Column(
      children: [
        if (_minhasObrasPendentes
            .isNotEmpty) ...[
          Padding(
            padding:
            const EdgeInsets.only(
              bottom: 8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .pending_actions_outlined,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  'Pendentes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                    color: Colors
                        .grey
                        .shade800,
                  ),
                ),
              ],
            ),
          ),
          ..._minhasObrasPendentes
              .map(_cartaoObraPendente),
        ],
        if (_minhasObras.isNotEmpty &&
            _minhasObrasPendentes
                .isNotEmpty)
          const SizedBox(height: 10),
        if (_minhasObras.isNotEmpty) ...[
          Padding(
            padding:
            const EdgeInsets.only(
              top: 4,
              bottom: 8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .library_books_outlined,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Text(
                  'Publicadas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                    color: Colors
                        .grey
                        .shade800,
                  ),
                ),
              ],
            ),
          ),
          ..._minhasObras
              .map(_cartaoObraPublicada),
        ],
      ],
    );
  }

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
        final obraDados =
        comentario['obras'];

        final obra =
        obraDados is Map
            ? Map<String, dynamic>.from(
          obraDados,
        )
            : <String, dynamic>{};

        final titulo =
        (obra['titulo'] ??
            'Obra')
            .toString();

        final obraId =
        (comentario['obra_id'] ??
            '')
            .toString();

        final comentarioTexto =
        (comentario['comentario'] ??
            comentario['texto'] ??
            '')
            .toString();

        final data =
        comentario['created_at'];

        return Card(
          margin:
          const EdgeInsets.only(
            bottom: 10,
          ),
          child: ListTile(
            leading:
            const CircleAvatar(
              child: Icon(
                Icons.comment_outlined,
              ),
            ),
            title: Text(
              titulo,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                if (comentarioTexto
                    .isNotEmpty)
                  Text(
                    comentarioTexto,
                    maxLines: 3,
                    overflow:
                    TextOverflow.ellipsis,
                  ),
                if (data != null)
                  Text(
                    _formatarData(data),
                  ),
              ],
            ),
            onTap: obraId.isEmpty
                ? null
                : () async {
              try {
                final obra =
                await _obrasRepository
                    .carregarPorId(
                  obraId,
                );

                if (obra != null &&
                    mounted) {
                  await _abrirDetalhesObra(
                    obra,
                  );
                }
              } catch (_) {}
            },
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
      children:
      _historico.map((item) {
        return Card(
          margin:
          const EdgeInsets.only(
            bottom: 10,
          ),
          child: ListTile(
            leading:
            const CircleAvatar(
              child: Icon(
                Icons.history,
              ),
            ),
            title: Text(
              item.titulo,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Consultada em '
                  '${_formatarData(item.dataConsulta)}',
            ),
          ),
        );
      }).toList(),
    );
  }

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
        final status =
        (solicitacao['status'] ??
            'pendente')
            .toString();

        final motivo =
        (solicitacao['motivo'] ??
            '')
            .toString();

        final obraDados =
        solicitacao['obras'];

        final obra =
        obraDados is Map
            ? Map<String, dynamic>.from(
          obraDados,
        )
            : <String, dynamic>{};

        final titulo =
        (obra['titulo'] ??
            'Obra')
            .toString();

        IconData icone;

        if (status == 'aprovada') {
          icone =
              Icons.check_circle_outline;
        } else if (status ==
            'rejeitada') {
          icone =
              Icons.cancel_outlined;
        } else {
          icone =
              Icons.hourglass_empty;
        }

        return Card(
          margin:
          const EdgeInsets.only(
            bottom: 10,
          ),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(icone),
            ),
            title: Text(
              titulo,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado: '
                      '${_formatarStatusSolicitacao(status)}',
                ),
                if (motivo.isNotEmpty)
                  Text(
                    'Motivo: $motivo',
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
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
    switch (status) {
      case 'aprovada':
        return 'Aprovada';

      case 'rejeitada':
        return 'Rejeitada';

      case 'pendente':
        return 'Pendente';

      default:
        return status;
    }
  }

  Widget _caixaVazia(
      String mensagem,
      IconData icone,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icone,
            size: 38,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // APP BAR — IGUAL À HOME
  // ===============================================================

  PreferredSizeWidget _buildAppBar() {
    final usuario =
        _supabase.auth.currentUser;

    final estaAutenticado =
        usuario != null;

    return AppBar(
      backgroundColor:
      const Color(0xFFEAF4FF),
      elevation: 0,
      surfaceTintColor:
      const Color(0xFFEAF4FF),
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      titleSpacing: 28,
      bottom: const PreferredSize(
        preferredSize:
        Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFD5E5F5),
        ),
      ),
      title: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () =>
                context.go('/'),
            child: const Text(
              'Obra Livre',
              style: TextStyle(
                color:
                Color(0xFF1F1F1F),
                fontSize: 21,
                fontWeight:
                FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),

          const SizedBox(width: 28),

          _buildNavButton(
            label: 'Plataforma',
            onPressed: () {
              context.go(
                '/plataforma',
              );
            },
          ),

          if (!estaAutenticado) ...[
            const SizedBox(width: 2),

            _buildNavButton(
              label: 'Acervo',
              onPressed: () {
                context.go('/acervo');
              },
            ),
          ],

          if (estaAutenticado &&
              !_ehAdmin) ...[
            const SizedBox(width: 2),

            _buildNavButton(
              label: 'Acervo',
              onPressed: () {
                context.go('/acervo');
              },
            ),

            const SizedBox(width: 2),

            _buildNavButton(
              label: 'Publicar',
              onPressed: () {
                context.go('/publicar');
              },
            ),
          ],
        ],
      ),
      actions: [
        if (estaAutenticado) ...[
          const SizedBox(width: 12),

          Padding(
            padding:
            const EdgeInsets.only(
              right: 24,
            ),
            child:
            PopupMenuButton<String>(
              tooltip: 'Conta',
              offset:
              const Offset(0, 50),
              elevation: 4,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              onSelected:
                  (value) async {
                switch (value) {
                  case 'conta':
                    _abrirConta();
                    break;

                  case 'configuracoes':
                    context.go(
                      '/minha-conta',
                    );
                    break;

                  case 'sair':
                    try {
                      await _authService
                          .sair();

                      if (!mounted) return;

                      context.go('/login');
                    } catch (e) {
                      debugPrint(
                        'MINHA CONTA: erro ao sair: $e',
                      );

                      if (!mounted) return;

                      _mostrarMensagem(
                        'Não foi possível terminar a sessão.',
                      );
                    }

                    break;
                }
              },
              itemBuilder:
                  (context) => [
                PopupMenuItem<String>(
                  value: 'conta',
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .person_outline,
                        size: 19,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        _ehAdmin
                            ? 'Administração'
                            : 'Minha conta',
                        style:
                        const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuItem<String>(
                  value:
                  'configuracoes',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .settings_outlined,
                        size: 19,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Configurações',
                        style:
                        TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                const PopupMenuItem<String>(
                  value: 'sair',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 19,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Sair',
                        style:
                        TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child:
              const AvatarUtilizador(
                radius: 20,
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            height: 38,
            child: TextButton(
              onPressed: () {
                context.go('/login');
              },
              style:
              TextButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF222222,
                ),
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                ),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Padding(
            padding:
            const EdgeInsets.only(
              right: 24,
            ),
            child: SizedBox(
              height: 38,
              child: TextButton(
                onPressed: () {
                  context.go(
                    '/cadastro',
                  );
                },
                style:
                TextButton.styleFrom(
                  backgroundColor:
                  const Color(
                    0xFFF7F7F7,
                  ),
                  foregroundColor:
                  const Color(
                    0xFF222222,
                  ),
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 18,
                  ),
                  side:
                  const BorderSide(
                    color: Color(
                      0xFFD8D8D8,
                    ),
                    width: 1,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                ),
                child: const Text(
                  'Criar conta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style:
      TextButton.styleFrom(
        foregroundColor:
        const Color(0xFF444444),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(7),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight:
          FontWeight.w500,
        ),
      ),
    );
  }

  void _abrirConta() {
    if (_ehAdmin) {
      context.go('/admin-obras');
    } else {
      context.go('/minha-conta');
    }
  }

  void _mostrarMensagem(
      String mensagem,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // ===============================================================
  // CONTEÚDO
  //
  // IGUAL À HOME:
  // maxWidth = 1100
  // padding horizontal = 24
  // ===============================================================

  Widget _conteudo() {
    return Center(
      child: ConstrainedBox(
        constraints:
        const BoxConstraints(
          maxWidth: 1100,
        ),
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            40,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _cartaoPerfil(),

              _tituloSecao(
                'Minhas publicações',
                icone: Icons
                    .library_books_outlined,
              ),

              _listaObras(),

              _tituloSecao(
                'Comentários',
                icone:
                Icons.comment_outlined,
              ),

              _listaComentarios(),

              _tituloSecao(
                'Solicitações de remoção',
                icone:
                Icons.delete_outline,
              ),

              _listaSolicitacoes(),

              _tituloSecao(
                'Histórico recente',
                icone: Icons.history,
                onVerTodos:
                _abrirHistorico,
              ),

              _listaHistorico(),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFCFCFC),
      appBar: _buildAppBar(),
      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _erro != null
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'Não foi possível carregar os dados.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                _erro!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(
                height: 18,
              ),
              FilledButton.icon(
                onPressed:
                _carregarDados,
                icon:
                const Icon(
                  Icons.refresh,
                ),
                label:
                const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        color:
        const Color(0xFF333333),
        backgroundColor:
        Colors.white,
        onRefresh:
        _carregarDados,
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          child: _conteudo(),
        ),
      ),
    );
  }
}

