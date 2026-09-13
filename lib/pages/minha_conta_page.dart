import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/obra.dart';
import '../models/obra_pendente.dart';
import '../repositories/obras_pendentes_repository.dart';
import '../repositories/obras_repository.dart';
import '../repositories/solicitacoes_remocao_repository.dart';
import '../services/auth_service.dart';
import '../widgets/detalhes_obra_dialog.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  final AuthService _authService = AuthService.instancia;

  List<Obra> _obrasPublicadas = [];
  List<ObraPendente> _obrasPendentes = [];
  List<Map<String, dynamic>> _solicitacoesRemocao = [];

  bool _carregando = true;
  bool _carregandoSolicitacoes = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    if (usuario == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    try {
      final resultados = await Future.wait<dynamic>([
        ObrasRepository.instancia
            .carregarMinhasObras(usuario.id),
        ObrasPendentesRepository.instancia
            .carregarDoUsuario(usuario.id),
        SolicitacoesRemocaoRepository.instancia
            .obterMinhasSolicitacoes(),
      ]);

      if (!mounted) return;

      setState(() {
        _obrasPublicadas =
        resultados[0] as List<Obra>;

        _obrasPendentes =
        resultados[1] as List<ObraPendente>;

        _solicitacoesRemocao =
        resultados[2] as List<Map<String, dynamic>>;

        _carregando = false;
        _carregandoSolicitacoes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _carregandoSolicitacoes = false;
      });

      _mostrarMensagem(
        'Não foi possível carregar os dados: $e',
      );
    }
  }

  Future<void> _atualizarSolicitacoes() async {
    try {
      final solicitacoes =
      await SolicitacoesRemocaoRepository.instancia
          .obterMinhasSolicitacoes();

      if (!mounted) return;

      setState(() {
        _solicitacoesRemocao = solicitacoes;
      });
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível atualizar os pedidos de remoção: $e',
      );
    }
  }

  Map<String, dynamic>? _solicitacaoDaObra(
      String obraId,
      ) {
    for (final solicitacao in _solicitacoesRemocao) {
      final id =
      solicitacao['obra_id']?.toString();

      if (id == obraId) {
        return solicitacao;
      }
    }

    return null;
  }

  String? _statusSolicitacao(String obraId) {
    final solicitacao =
    _solicitacaoDaObra(obraId);

    return solicitacao?['status']?.toString();
  }

  Future<void> _solicitarRemocao(Obra obra) async {
    final status =
    _statusSolicitacao(obra.id);

    if (status == 'pendente') {
      _mostrarMensagem(
        'Já existe um pedido de remoção em análise.',
      );
      return;
    }

    if (status == 'aprovada') {
      _mostrarMensagem(
        'Esta obra já possui uma remoção aprovada.',
      );
      return;
    }

    final controlador = TextEditingController();

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Solicitar remoção'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  obra.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Explique o motivo pelo qual pretende '
                      'solicitar a remoção desta obra.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controlador,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                    'Motivo da remoção...',
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(6),
                    ),
                    contentPadding:
                    const EdgeInsets.all(12),
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
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final motivo =
                controlador.text.trim();

                if (motivo.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext)
                    .pop(motivo);
              },
              child: const Text('Enviar pedido'),
            ),
          ],
        );
      },
    );

    controlador.dispose();

    if (resultado == null ||
        resultado.trim().isEmpty) {
      return;
    }

    try {
      await SolicitacoesRemocaoRepository
          .instancia
          .criarSolicitacao(
        obraId: obra.id,
        motivo: resultado.trim(),
      );

      await _atualizarSolicitacoes();

      if (!mounted) return;

      _mostrarMensagem(
        'Pedido de remoção enviado para análise.',
      );
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(
        'Não foi possível enviar o pedido: $e',
      );
    }
  }

  Future<void> _abrirDetalhesObra(Obra obra) async {
    final status =
    _statusSolicitacao(obra.id);

    final podeSolicitarRemocao =
        status != 'pendente' &&
            status != 'aprovada';

    await mostrarDetalhesObraDialog(
      context,
      obra: obra,
      statusRemocao: status,
      mostrarSolicitarRemocao:
      podeSolicitarRemocao,
      mostrarAbrir: true,
      onSolicitarRemocao: () {
        _solicitarRemocao(obra);
      },
      onAbrir: () {
        _abrirDocumento(obra);
      },
    );
  }

  void _abrirDocumento(Obra obra) {
    final url = obra.urlDocumento.trim();

    if (url.isEmpty) {
      _mostrarMensagem(
        'Esta obra não possui um documento disponível.',
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      _mostrarMensagem(
        'O endereço do documento é inválido.',
      );
      return;
    }

    html.window.open(url, '_blank');
  }

  String _iniciais(String? nome) {
    final valor = nome?.trim() ?? '';

    if (valor.isEmpty) {
      return '?';
    }

    final partes = valor
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.length == 1) {
      return partes.first
          .substring(0, 1)
          .toUpperCase();
    }

    return (
        partes.first.substring(0, 1) +
            partes.last.substring(0, 1)
    ).toUpperCase();
  }

  String _nomeUsuario() {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    final metadata = usuario?.userMetadata;

    final nome =
    metadata?['nome']?.toString().trim();

    if (nome != null && nome.isNotEmpty) {
      return nome;
    }

    final nomeCompleto =
    metadata?['full_name']?.toString().trim();

    if (nomeCompleto != null &&
        nomeCompleto.isNotEmpty) {
      return nomeCompleto;
    }

    final nomePerfil =
    metadata?['name']?.toString().trim();

    if (nomePerfil != null &&
        nomePerfil.isNotEmpty) {
      return nomePerfil;
    }

    final email = usuario?.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Utilizador';
  }

  String _emailUsuario() {
    return Supabase.instance.client.auth
        .currentUser?.email ??
        '';
  }

  String _tituloObraPendente(
      ObraPendente obra,
      ) {
    return obra.titulo;
  }

  Widget _avatarUsuario() {
    final usuario =
        Supabase.instance.client.auth.currentUser;

    final metadata = usuario?.userMetadata;

    final avatar =
        metadata?['avatar_url']?.toString() ??
            metadata?['picture']?.toString() ??
            metadata?['photo_url']?.toString();

    if (avatar != null &&
        avatar.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 38,
        backgroundImage:
        NetworkImage(avatar),
      );
    }

    return CircleAvatar(
      radius: 38,
      child: Text(
        _iniciais(_nomeUsuario()),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _secao({
    required String titulo,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildVazio(String mensagem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Text(
        mensagem,
        style: TextStyle(
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _cardObraPublicada(Obra obra) {
    final status =
    _statusSolicitacao(obra.id);

    return InkWell(
      onTap: () =>
          _abrirDetalhesObra(obra),
      borderRadius:
      BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          borderRadius:
          BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                Colors.grey.shade100,
                borderRadius:
                BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 21,
              ),
            ),
            const SizedBox(width: 14),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    obra.autor,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.grey.shade600,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 8),
                    _badgeStatus(status),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardObraPendente(
      ObraPendente obra,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
              BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _tituloObraPendente(obra),
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aguardando análise',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStatus(String status) {
    String texto;
    Color cor;

    switch (status) {
      case 'pendente':
        texto = 'Remoção em análise';
        cor = Colors.orange;
        break;

      case 'aprovada':
        texto = 'Remoção aprovada';
        cor = Colors.green;
        break;

      case 'rejeitada':
        texto = 'Pedido rejeitado';
        cor = Colors.red;
        break;

      default:
        texto = status;
        cor = Colors.grey;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.10),
        borderRadius:
        BorderRadius.circular(5),
      ),
      child: Text(
        texto,
        style: TextStyle(
          // CORRIGIDO: Color não possui .shade
          color: cor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _cardSolicitacao(
      Map<String, dynamic> solicitacao,
      ) {
    final obra =
    solicitacao['obras']
    as Map<String, dynamic>?;

    final titulo =
        obra?['titulo']?.toString() ??
            'Obra não encontrada';

    final status =
        solicitacao['status']?.toString() ??
            '';

    final motivo =
        solicitacao['motivo']?.toString() ??
            '';

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(bottom: 10),
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 9),
          _badgeStatus(status),
          if (motivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              motivo,
              style: TextStyle(
                fontSize: 13,
                color:
                Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
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
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _nomeUsuario();
    final email = _emailUsuario();

    return Scaffold(
      backgroundColor:
      Colors.grey.shade50,
      appBar: AppBar(
        title:
        const Text('Minha conta'),
        elevation: 0,
        backgroundColor:
        Colors.white,
        foregroundColor:
        Colors.black87,
        leading: IconButton(
          tooltip: 'Voltar',
          icon:
          const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
      ),
      body: _carregando
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 900,
          ),
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets.all(
                    22,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    border:
                    Border.all(
                      color: Colors
                          .grey
                          .shade200,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      8,
                    ),
                  ),
                  child: Row(
                    children: [
                      _avatarUsuario(),
                      const SizedBox(
                        width: 18,
                      ),
                      Expanded(
                        child:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              nome,
                              style:
                              const TextStyle(
                                fontSize:
                                20,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                            if (email
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 5,
                              ),
                              Text(
                                email,
                                style:
                                TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                _secao(
                  titulo:
                  'Minhas publicações',
                  child: _obrasPublicadas
                      .isEmpty
                      ? _buildVazio(
                    'Ainda não possui obras publicadas.',
                  )
                      : Column(
                    children:
                    _obrasPublicadas
                        .map(
                          (obra) =>
                          Padding(
                            padding:
                            const EdgeInsets.only(
                              bottom:
                              10,
                            ),
                            child:
                            _cardObraPublicada(
                              obra,
                            ),
                          ),
                    )
                        .toList(),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                _secao(
                  titulo:
                  'Publicações em análise',
                  child: _obrasPendentes
                      .isEmpty
                      ? _buildVazio(
                    'Não possui publicações aguardando análise.',
                  )
                      : Column(
                    children:
                    _obrasPendentes
                        .map(
                          (obra) =>
                          Padding(
                            padding:
                            const EdgeInsets.only(
                              bottom:
                              10,
                            ),
                            child:
                            _cardObraPendente(
                              obra,
                            ),
                          ),
                    )
                        .toList(),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                _secao(
                  titulo:
                  'Pedidos de remoção',
                  child:
                  _carregandoSolicitacoes
                      ? const Center(
                    child:
                    CircularProgressIndicator(),
                  )
                      : _solicitacoesRemocao
                      .isEmpty
                      ? _buildVazio(
                    'Ainda não possui pedidos de remoção.',
                  )
                      : Column(
                    children:
                    _solicitacoesRemocao
                        .map(
                          (solicitacao) =>
                          _cardSolicitacao(
                            solicitacao,
                          ),
                    )
                        .toList(),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Align(
                  alignment:
                  Alignment.centerLeft,
                  child:
                  TextButton.icon(
                    onPressed:
                        () async {
                      await _authService
                          .sair();

                      if (!mounted)
                        return;

                      context.go(
                        '/login',
                      );
                    },
                    icon:
                    const Icon(
                      Icons.logout,
                      size: 18,
                    ),
                    label:
                    const Text(
                      'Sair',
                    ),
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
