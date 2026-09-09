import 'package:flutter/material.dart';

import '../models/obra_pendente.dart';
import '../services/admin_service.dart';

class AdminObrasPage extends StatefulWidget {
  const AdminObrasPage({
    super.key,
  });

  @override
  State<AdminObrasPage> createState() =>
      _AdminObrasPageState();
}

class _AdminObrasPageState
    extends State<AdminObrasPage> {
  final AdminService _admin =
      AdminService.instancia;

  List<ObraPendente> _obras = [];

  bool _carregando = true;
  bool _processando = false;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ============================================================
  // CARREGAR OBRAS
  // ============================================================

  Future<void> _carregar() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final obras =
      await _admin.carregarObrasPendentes();

      if (!mounted) return;

      setState(() {
        _obras = obras;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = _mensagemErro(e);
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });
    }
  }

  // ============================================================
  // APROVAR
  // ============================================================

  Future<void> _aprovar(
      ObraPendente obra,
      ) async {
    if (obra.id == null) {
      return;
    }

    final confirmar =
    await _mostrarConfirmacao(
      titulo: 'Aprovar obra',
      mensagem:
      'Deseja aprovar a obra "${obra.titulo}"?',
      textoConfirmar: 'Aprovar',
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await _admin.aprovarObra(
        obra.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra aprovada com sucesso.',
          ),
        ),
      );

      await _carregar();
    } catch (e) {
      if (!mounted) return;

      _mostrarErro(
        _mensagemErro(e),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _processando = false;
      });
    }
  }

  // ============================================================
  // REJEITAR
  // ============================================================

  Future<void> _rejeitar(
      ObraPendente obra,
      ) async {
    if (obra.id == null) {
      return;
    }

    final confirmar =
    await _mostrarConfirmacao(
      titulo: 'Rejeitar obra',
      mensagem:
      'Deseja rejeitar a obra "${obra.titulo}"?',
      textoConfirmar: 'Rejeitar',
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await _admin.rejeitarObra(
        obra.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra rejeitada.',
          ),
        ),
      );

      await _carregar();
    } catch (e) {
      if (!mounted) return;

      _mostrarErro(
        _mensagemErro(e),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _processando = false;
      });
    }
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<void> _excluir(
      ObraPendente obra,
      ) async {
    if (obra.id == null) {
      return;
    }

    final confirmar =
    await _mostrarConfirmacao(
      titulo: 'Excluir obra',
      mensagem:
      'Esta ação irá remover a obra e o documento pendente. Deseja continuar?',
      textoConfirmar: 'Excluir',
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await _admin.excluirObra(
        obra.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra excluída com sucesso.',
          ),
        ),
      );

      await _carregar();
    } catch (e) {
      if (!mounted) return;

      _mostrarErro(
        _mensagemErro(e),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _processando = false;
      });
    }
  }

  // ============================================================
  // CONFIRMAÇÃO
  // ============================================================

  Future<bool?> _mostrarConfirmacao({
    required String titulo,
    required String mensagem,
    required String textoConfirmar,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MOSTRAR ERRO
  // ============================================================

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  // ============================================================
  // FORMATAR DATA
  // ============================================================

  String _formatarData(
      DateTime? data,
      ) {
    if (data == null) {
      return 'Data não disponível';
    }

    final dia =
    data.day.toString().padLeft(2, '0');

    final mes =
    data.month.toString().padLeft(2, '0');

    final ano =
    data.year.toString();

    return '$dia/$mes/$ano';
  }

  // ============================================================
  // MENSAGEM DE ERRO
  // ============================================================

  String _mensagemErro(Object erro) {
    final mensagem =
    erro.toString();

    if (mensagem.startsWith('Exception: ')) {
      return mensagem.substring(11);
    }

    return mensagem;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administração de Obras',
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed:
            _carregando || _processando
                ? null
                : _carregar,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _construirConteudo(),
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _construirConteudo() {
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
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                _processando
                    ? null
                    : _carregar,
                child: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_obras.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Não existem obras pendentes.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _carregar,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _obras.length,
            itemBuilder: (
                context,
                index,
                ) {
              return _construirCard(
                _obras[index],
              );
            },
          ),
        ),

        if (_processando)
          Positioned.fill(
            child: Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CARD DA OBRA
  // ============================================================

  Widget _construirCard(
      ObraPendente obra,
      ) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              obra.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _linha(
              'Autor',
              obra.autor,
            ),

            _linha(
              'Categoria',
              obra.categoria,
            ),

            if (obra.anoObra != null)
              _linha(
                'Ano',
                obra.anoObra.toString(),
              ),

            _linha(
              'Data',
              _formatarData(
                obra.dataPublicacao,
              ),
            ),

            if (obra.descricao != null &&
                obra.descricao!.trim().isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.only(
                  top: 10,
                ),
                child: Text(
                  obra.descricao!,
                  maxLines: 3,
                  overflow:
                  TextOverflow.ellipsis,
                ),
              ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed:
                  _processando
                      ? null
                      : () => _rejeitar(
                    obra,
                  ),
                  child: const Text(
                    'Rejeitar',
                  ),
                ),

                const SizedBox(width: 8),

                TextButton(
                  onPressed:
                  _processando
                      ? null
                      : () => _excluir(
                    obra,
                  ),
                  child: const Text(
                    'Excluir',
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed:
                  _processando
                      ? null
                      : () => _aprovar(
                    obra,
                  ),
                  child: const Text(
                    'Aprovar',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LINHA DE INFORMAÇÃO
  // ============================================================

  Widget _linha(
      String titulo,
      String valor,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(valor),
          ),
        ],
      ),
    );
  }
}

