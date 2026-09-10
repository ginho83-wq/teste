import 'package:flutter/material.dart';

import '../models/obra_pendente.dart';
import '../services/admin_service.dart';

class AdminObrasPage extends StatefulWidget {
  const AdminObrasPage({
    super.key,
  });

  @override
  State<AdminObrasPage> createState() => _AdminObrasPageState();
}

class _AdminObrasPageState extends State<AdminObrasPage> {
  final AdminService _admin = AdminService.instancia;

  List<ObraPendente> _obras = [];

  bool _carregando = true;
  String? _erro;
  String? _processandoId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ============================================================
  // CARREGAR
  // ============================================================

  Future<void> _carregar() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final obras = await _admin.carregarObrasPendentes();

      if (!mounted) return;

      setState(() {
        _obras = obras;
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

  // ============================================================
  // APROVAR
  // ============================================================

  Future<void> _aprovar(ObraPendente obra) async {
    final id = obra.id;

    if (id == null || id.isEmpty) {
      _mostrarErro('ID da obra inválido.');
      return;
    }

    final confirmar = await _confirmar(
      titulo: 'Aprovar publicação',
      mensagem:
      'Deseja aprovar esta obra e disponibilizá-la publicamente?',
      textoConfirmar: 'Aprovar',
    );

    if (!confirmar) return;

    if (!mounted) return;

    setState(() {
      _processandoId = id;
      _erro = null;
    });

    try {
      await _admin.aprovarObra(id);

      if (!mounted) return;

      setState(() {
        _obras.removeWhere((item) => item.id == id);
        _processandoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra aprovada e publicada com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processandoId = null;
        _erro = _mensagemErro(e);
      });

      _mostrarErro(_mensagemErro(e));
    }
  }

  // ============================================================
  // REJEITAR
  // ============================================================

  Future<void> _rejeitar(ObraPendente obra) async {
    final id = obra.id;

    if (id == null || id.isEmpty) {
      _mostrarErro('ID da obra inválido.');
      return;
    }

    final confirmar = await _confirmar(
      titulo: 'Rejeitar publicação',
      mensagem:
      'Deseja rejeitar esta obra? O documento pendente será removido.',
      textoConfirmar: 'Rejeitar',
    );

    if (!confirmar) return;

    if (!mounted) return;

    setState(() {
      _processandoId = id;
      _erro = null;
    });

    try {
      await _admin.rejeitarObra(id);

      if (!mounted) return;

      setState(() {
        _obras.removeWhere((item) => item.id == id);
        _processandoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Obra rejeitada com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processandoId = null;
        _erro = _mensagemErro(e);
      });

      _mostrarErro(_mensagemErro(e));
    }
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<void> _excluir(ObraPendente obra) async {
    final id = obra.id;

    if (id == null || id.isEmpty) {
      _mostrarErro('ID da obra inválido.');
      return;
    }

    final confirmar = await _confirmar(
      titulo: 'Excluir publicação',
      mensagem:
      'Deseja excluir definitivamente esta publicação pendente?',
      textoConfirmar: 'Excluir',
    );

    if (!confirmar) return;

    if (!mounted) return;

    setState(() {
      _processandoId = id;
      _erro = null;
    });

    try {
      await _admin.excluirObra(id);

      if (!mounted) return;

      setState(() {
        _obras.removeWhere((item) => item.id == id);
        _processandoId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Publicação excluída com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _processandoId = null;
        _erro = _mensagemErro(e);
      });

      _mostrarErro(_mensagemErro(e));
    }
  }

  // ============================================================
  // CONFIRMAÇÃO
  // ============================================================

  Future<bool> _confirmar({
    required String titulo,
    required String mensagem,
    required String textoConfirmar,
  }) async {
    final resultado = await showDialog<bool>(
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
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(textoConfirmar),
            ),
          ],
        );
      },
    );

    return resultado ?? false;
  }

  // ============================================================
  // MENSAGEM DE ERRO
  // ============================================================

  String _mensagemErro(Object erro) {
    final mensagem = erro.toString();

    if (mensagem.startsWith('Exception: ')) {
      return mensagem.substring('Exception: '.length);
    }

    return mensagem;
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  // ============================================================
  // DATA
  // ============================================================

  String _formatarData(DateTime? data) {
    if (data == null) {
      return '—';
    }

    final local = data.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
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

    if (_erro != null && _obras.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
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
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _carregar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_obras.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 56,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Não existem publicações pendentes.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_erro != null) ...[
            _MensagemErroWidget(
              mensagem: _erro!,
              onFechar: () {
                setState(() {
                  _erro = null;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Publicações pendentes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${_obras.length} publicação(ões) aguardando análise.',
          ),
          const SizedBox(height: 24),
          ..._obras.map(_buildObraCard),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildObraCard(ObraPendente obra) {
    final id = obra.id;
    final processando = id != null && _processandoId == id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              obra.titulo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _InfoLinha(
              icone: Icons.person_outline,
              texto: obra.autor,
            ),
            const SizedBox(height: 6),
            _InfoLinha(
              icone: Icons.category_outlined,
              texto: obra.categoria,
            ),
            if (obra.anoObra != null) ...[
              const SizedBox(height: 6),
              _InfoLinha(
                icone: Icons.calendar_today_outlined,
                texto: obra.anoObra.toString(),
              ),
            ],
            const SizedBox(height: 6),
            _InfoLinha(
              icone: Icons.schedule_outlined,
              texto:
              'Enviada em ${_formatarData(obra.dataPublicacao)}',
            ),
            if (obra.descricao != null &&
                obra.descricao!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                obra.descricao!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),
            if (processando)
              const Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _rejeitar(obra),
                    child: const Text('Rejeitar'),
                  ),
                  OutlinedButton(
                    onPressed: () => _excluir(obra),
                    child: const Text('Excluir'),
                  ),
                  FilledButton(
                    onPressed: () => _aprovar(obra),
                    child: const Text('Aprovar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// INFO LINHA
// ============================================================

class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _InfoLinha({
    required this.icone,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icone,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto),
        ),
      ],
    );
  }
}

// ============================================================
// MENSAGEM DE ERRO
// ============================================================

class _MensagemErroWidget extends StatelessWidget {
  final String mensagem;
  final VoidCallback onFechar;

  const _MensagemErroWidget({
    required this.mensagem,
    required this.onFechar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context)
                  .colorScheme
                  .onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onErrorContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: onFechar,
              icon: const Icon(Icons.close),
              color: Theme.of(context)
                  .colorScheme
                  .onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }
}
