import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/historico_obra.dart';
import '../models/obra.dart';
import '../repositories/obras_repository.dart';
import '../repositories/solicitacoes_remocao_repository.dart';
import '../services/historico_obras_service.dart';
import '../widgets/detalhes_obra_dialog.dart';
import '../widgets/avatar_utilizador.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() =>
      _MinhaContaPageState();
}

class _MinhaContaPageState
    extends State<MinhaContaPage> {
  final SupabaseClient _supabase =
      Supabase.instance.client;

  final ObrasRepository _obrasRepository =
      ObrasRepository.instancia;

  final SolicitacoesRemocaoRepository
  _solicitacoesRepository =
      SolicitacoesRemocaoRepository.instancia;

  final HistoricoObrasService _historicoService =
  HistoricoObrasService();

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
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final usuario =
          _supabase.auth.currentUser;

      if (usuario == null) {
        throw Exception(
          'Utilizador não autenticado. Entre novamente na sua conta.',
        );
      }

      final perfilResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', usuario.id)
          .maybeSingle();

      final obras =
      await _obterMinhasObras(usuario.id);

      final solicitacoes =
      await _solicitacoesRepository
          .obterMinhasSolicitacoes();

      List<HistoricoObra> historico = [];

      try {
        historico =
        await _historicoService
            .obterConsultasRecentes(
          limite: 5,
        );
      } catch (e) {
        debugPrint(
          'Erro ao carregar histórico de obras consultadas: $e',
        );
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfilResponse;
        _minhasObras = obras;
        _solicitacoes = solicitacoes;
        _historico = historico;
        _carregando = false;
      });
    } catch (e) {
      debugPrint(
        'Erro ao carregar Minha Conta: $e',
      );

      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>>
  _obterMinhasObras(
      String userId,
      ) async {
    final resposta = await _supabase
        .from('obras')
        .select()
        .eq('user_id', userId)
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(
      resposta,
    );
  }

  Future<void> _abrirDetalhesObra(
      Map<String, dynamic> dados,
      ) async {
    try {
      final obra = Obra.fromMap(dados);

      await mostrarDetalhesObraDialog(
        context,
        obra: obra,
        mostrarSolicitarRemocao: true,
        mostrarAbrir: true,
        onSolicitarRemocao: () {
          _solicitarRemocao(obra);
        },
        onAbrir: () async {
          final url =
          dados['url_documento']
              ?.toString()
              .trim();

          if (url == null || url.isEmpty) {
            if (!mounted) return;

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Esta obra não possui um documento disponível.',
                ),
              ),
            );

            return;
          }

          final uri = Uri.tryParse(url);

          if (uri == null ||
              (uri.scheme != 'http' &&
                  uri.scheme != 'https')) {
            if (!mounted) return;

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'O endereço do documento é inválido.',
                ),
              ),
            );

            return;
          }

          try {
            final abriu = await launchUrl(
              uri,
              webOnlyWindowName: '_blank',
            );

            if (!abriu && mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Não foi possível abrir o documento.',
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint(
              'Erro ao abrir documento da obra: $e',
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível abrir o documento.',
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint(
        'Erro ao abrir detalhes da obra: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível abrir os detalhes da obra: $e',
          ),
        ),
      );
    }
  }

  Future<void> _solicitarRemocao(
      Obra obra,
      ) async {
    final resultado =
    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller =
        TextEditingController();

        return AlertDialog(
          title:
          const Text('Solicitar remoção'),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Solicite a remoção da obra:',
                style: TextStyle(
                  color:
                  Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                obra.titulo,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration:
                const InputDecoration(
                  labelText:
                  'Motivo da remoção',
                  hintText:
                  'Informe o motivo da solicitação...',
                  border:
                  OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final motivo =
                controller.text.trim();

                if (motivo.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Informe o motivo da remoção.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(motivo);
              },
              child: const Text(
                'Enviar pedido',
              ),
            ),
          ],
        );
      },
    );

    if (resultado == null ||
        resultado.trim().isEmpty) {
      return;
    }

    try {
      await _solicitacoesRepository
          .criarSolicitacao(
        obraId: obra.id,
        motivo: resultado.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Pedido de remoção enviado para análise.',
          ),
        ),
      );

      await _carregarDados();
    } catch (e) {
      debugPrint(
        'Erro ao solicitar remoção da obra: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível enviar o pedido: $e',
          ),
        ),
      );
    }
  }

  Future<void> _abrirHistorico(
      HistoricoObra obra,
      ) async {
    final url =
    obra.urlDocumento?.trim();

    if (url == null || url.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Esta obra não possui um documento disponível.',
          ),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' &&
            uri.scheme != 'https')) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'O endereço do documento é inválido.',
          ),
        ),
      );

      return;
    }

    try {
      final abriu = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );

      if (!abriu) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível abrir o documento.',
            ),
          ),
        );

        return;
      }

      try {
        await _historicoService
            .registrarConsulta(
          obraId: obra.obraId,
        );

        await _carregarHistorico();
      } catch (e) {
        debugPrint(
          'Erro ao atualizar data da consulta: $e',
        );
      }
    } catch (e) {
      debugPrint(
        'Erro ao abrir documento do histórico: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o documento.',
          ),
        ),
      );
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
    } catch (e) {
      debugPrint(
        'Erro ao atualizar histórico: $e',
      );
    }
  }

  String _formatarData(
      DateTime data,
      ) {
    final dataLocal =
    data.toLocal();

    final dia =
    dataLocal.day
        .toString()
        .padLeft(2, '0');

    final mes =
    dataLocal.month
        .toString()
        .padLeft(2, '0');

    final ano =
    dataLocal.year.toString();

    final hora =
    dataLocal.hour
        .toString()
        .padLeft(2, '0');

    final minuto =
    dataLocal.minute
        .toString()
        .padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  Widget _tituloSecao(
      String titulo, {
        Widget? acao,
      }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style:
              const TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          if (acao != null) acao,
        ],
      ),
    );
  }

  Widget _cartaoPerfil() {
    final usuario =
        _supabase.auth.currentUser;

    final nome =
    (_perfil?['nome'] ?? '')
        .toString()
        .trim();

    final email =
    (_perfil?['email'] ??
        usuario?.email ??
        '')
        .toString()
        .trim();

    final role =
    (_perfil?['role'] ?? 'user')
        .toString()
        .trim();

    final nomeExibicao =
    nome.isNotEmpty
        ? nome
        : 'Utilizador';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Row(
          children: [
            AvatarUtilizador(
              radius: 28,
              perfil: _perfil,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeExibicao,
                    style:
                    const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color:
                        Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    role == 'admin'
                        ? 'Administrador'
                        : 'Utilizador',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      Colors.grey.shade600,
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
        icon:
        Icons.menu_book_outlined,
        mensagem:
        'Ainda não publicou nenhuma obra.',
      );
    }

    return Column(
      children:
      _minhasObras.map((obra) {
        final titulo =
        (obra['titulo'] ??
            'Sem título')
            .toString();

        final autor =
        (obra['autor'] ?? '')
            .toString();

        final categoria =
        (obra['categoria'] ?? '')
            .toString();

        return Card(
          elevation: 0,
          margin:
          const EdgeInsets.only(
            bottom: 10,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(8),
            side: BorderSide(
              color:
              Colors.grey.shade300,
            ),
          ),
          child: ListTile(
            onTap: () =>
                _abrirDetalhesObra(
                  obra,
                ),
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: CircleAvatar(
              backgroundColor:
              Colors.grey.shade100,
              child: const Icon(
                Icons.menu_book_outlined,
                color:
                Colors.black54,
              ),
            ),
            title: Text(
              titulo,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding:
              const EdgeInsets.only(
                top: 5,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  if (autor.isNotEmpty)
                    Text(autor),
                  if (categoria.isNotEmpty)
                    Text(
                      categoria,
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            trailing:
            const Icon(
              Icons.chevron_right,
              color: Colors.black54,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _listaHistorico() {
    if (_historico.isEmpty) {
      return _caixaVazia(
        icon: Icons.history,
        mensagem:
        'Ainda não consultou nenhuma obra.',
      );
    }

    return Column(
      children:
      _historico.map((obra) {
        final titulo =
        obra.titulo.trim().isNotEmpty
            ? obra.titulo.trim()
            : 'Obra sem título';

        final autor =
            obra.autor?.trim() ?? '';

        final categoria =
            obra.categoria?.trim() ?? '';

        return Card(
          elevation: 0,
          margin:
          const EdgeInsets.only(
            bottom: 10,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(8),
            side: BorderSide(
              color:
              Colors.grey.shade300,
            ),
          ),
          child: ListTile(
            onTap: () =>
                _abrirHistorico(obra),
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 7,
            ),
            leading: CircleAvatar(
              backgroundColor:
              Colors.grey.shade100,
              child: const Icon(
                Icons.history,
                color:
                Colors.black54,
              ),
            ),
            title: Text(
              titulo,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding:
              const EdgeInsets.only(
                top: 5,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  if (autor.isNotEmpty)
                    Text(
                      autor,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  if (categoria.isNotEmpty)
                    Text(
                      categoria,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    'Consultado em ${_formatarData(obra.dataConsulta)}',
                    style: TextStyle(
                      color: Colors
                          .grey
                          .shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing:
            const Icon(
              Icons.open_in_new,
              size: 20,
              color: Colors.black54,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _listaSolicitacoes() {
    if (_solicitacoes.isEmpty) {
      return _caixaVazia(
        icon:
        Icons.delete_outline,
        mensagem:
        'Não possui pedidos de remoção.',
      );
    }

    return Column(
      children:
      _solicitacoes.map(
            (solicitacao) {
          final titulo =
          (solicitacao[
          'obra_titulo'] ??
              solicitacao[
              'titulo'] ??
              'Obra')
              .toString();

          final motivo =
          (solicitacao['motivo'] ??
              '')
              .toString();

          final estado =
          (solicitacao['estado'] ??
              solicitacao[
              'status'] ??
              'pendente')
              .toString();

          return Card(
            elevation: 0,
            margin:
            const EdgeInsets.only(
              bottom: 10,
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                8,
              ),
              side: BorderSide(
                color:
                Colors.grey.shade300,
              ),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor:
                Colors.grey.shade100,
                child: const Icon(
                  Icons.delete_outline,
                  color:
                  Colors.black54,
                ),
              ),
              title: Text(
                titulo,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding:
                const EdgeInsets.only(
                  top: 5,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    if (motivo.isNotEmpty)
                      Text(
                        motivo,
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Estado: $estado',
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _caixaVazia({
    required IconData icon,
    required String mensagem,
  }) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color:
            Colors.grey.shade500,
          ),
          const SizedBox(height: 10),
          Text(
            mensagem,
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView(
        padding:
        const EdgeInsets.all(24),
        children: [
          const Text(
            'Minha conta',
            style: TextStyle(
              fontSize: 28,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Consulte os seus dados, obras e atividade recente.',
            style: TextStyle(
              color:
              Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          _cartaoPerfil(),
          const SizedBox(height: 30),
          _tituloSecao(
            'Minhas obras',
          ),
          _listaObras(),
          const SizedBox(height: 30),
          _tituloSecao(
            'Obras consultadas recentemente',
            acao: TextButton(
              onPressed: () {
                context.go(
                  '/historico-obras',
                );
              },
              child: const Text(
                'Ver histórico completo',
              ),
            ),
          ),
          _listaHistorico(),
          const SizedBox(height: 30),
          _tituloSecao(
            'Pedidos de remoção',
          ),
          _listaSolicitacoes(),
          const SizedBox(height: 30),
          SizedBox(
            height: 48,
            child:
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await _supabase
                      .auth
                      .signOut();

                  if (!mounted) return;

                  context.go('/login');
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Não foi possível sair: $e',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.logout,
              ),
              label: const Text(
                'Sair da conta',
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Colors.white,
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Minha conta',
          style: TextStyle(
            color: Colors.black,
            fontWeight:
            FontWeight.w600,
          ),
        ),
        iconTheme:
        const IconThemeData(
          color: Colors.black,
        ),
      ),
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
                size: 42,
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'Não foi possível carregar os dados da conta.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                _erro!,
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color: Colors
                      .grey
                      .shade700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              ElevatedButton.icon(
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
          : _conteudo(),
    );
  }
}

