import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _senhaController =
  TextEditingController();

  final TextEditingController _confirmarSenhaController =
  TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;

  // Listener guardado para poder ser removido corretamente no dispose.
  late final VoidCallback _senhaListener;

  @override
  void initState() {
    super.initState();

    _senhaListener = () {
      setState(() {});
    };

    _senhaController.addListener(_senhaListener);
  }

  // ============================================================
  // FORÇA DA PALAVRA-PASSE
  // ============================================================

  int _forcaSenha(String senha) {
    if (senha.isEmpty) {
      return 0;
    }

    int pontos = 0;

    // Comprimento
    if (senha.length >= 6) {
      pontos++;
    }

    if (senha.length >= 8) {
      pontos++;
    }

    // Letras minúsculas
    if (RegExp(r'[a-z]').hasMatch(senha)) {
      pontos++;
    }

    // Letras maiúsculas
    if (RegExp(r'[A-Z]').hasMatch(senha)) {
      pontos++;
    }

    // Números
    if (RegExp(r'[0-9]').hasMatch(senha)) {
      pontos++;
    }

    // Caracteres especiais
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(senha)) {
      pontos++;
    }

    if (pontos <= 2) {
      return 1;
    }

    if (pontos <= 4) {
      return 2;
    }

    return 3;
  }

  String _textoForcaSenha(int forca) {
    switch (forca) {
      case 1:
        return 'Fraca';
      case 2:
        return 'Média';
      case 3:
        return 'Forte';
      default:
        return '';
    }
  }

  Color _corForcaSenha(int forca) {
    switch (forca) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  // ============================================================
  // CRIAR CONTA
  // ============================================================

  Future<void> _criarConta() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha = _confirmarSenhaController.text;

    if (email.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      _mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (senha != confirmarSenha) {
      _mostrarMensagem(
        'As palavras-passe não coincidem.',
      );
      return;
    }

    if (senha.length < 6) {
      _mostrarMensagem(
        'A palavra-passe deve ter pelo menos 6 caracteres.',
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await AuthService.instancia.criarConta(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      _mostrarMensagem(
        'Conta criada. Verifique o email caso a confirmação esteja ativada.',
      );

      context.go('/login');
    } on AuthException catch (e) {
      _mostrarMensagem(e.message);
    } catch (e) {
      _mostrarMensagem(
        'Erro ao criar conta: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
      ),
    );
  }

  @override
  void dispose() {
    _senhaController.removeListener(_senhaListener);

    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    super.dispose();
  }

  // ============================================================
  // CAMPO DE PALAVRA-PASSE
  // ============================================================

  Widget _campoSenha({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required bool mostrarSenha,
    required VoidCallback alternarVisibilidade,
  }) {
    return TextField(
      controller: controller,
      obscureText: !mostrarSenha,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,

        suffixIcon: IconButton(
          tooltip: mostrarSenha
              ? 'Ocultar palavra-passe'
              : 'Mostrar palavra-passe',
          icon: Icon(
            mostrarSenha
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed: alternarVisibilidade,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            width: 1.5,
          ),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ============================================================
  // BARRA DE FORÇA
  // ============================================================

  Widget _barraForcaSenha() {
    final senha = _senhaController.text;
    final forca = _forcaSenha(senha);

    if (senha.isEmpty) {
      return const SizedBox.shrink();
    }

    final cor = _corForcaSenha(forca);
    final texto = _textoForcaSenha(forca);

    double valor;

    switch (forca) {
      case 1:
        valor = 1 / 3;
        break;
      case 2:
        valor = 2 / 3;
        break;
      case 3:
        valor = 1;
        break;
      default:
        valor = 0;
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        left: 2,
        right: 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: valor,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                AlwaysStoppedAnimation<Color>(cor),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // CABEÇALHO
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              child: Row(
                children: [
                  const Text(
                    'Teste',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTEÚDO
            // ==================================================

            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Criar a sua conta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Crie uma conta para começar a utilizar o Teste.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ======================================
                        // EMAIL
                        // ======================================

                        TextField(
                          controller: _emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Digite o seu email',

                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                            ),

                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(8),
                              borderSide:
                              const BorderSide(
                                width: 1.5,
                              ),
                            ),

                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ======================================
                        // PALAVRA-PASSE
                        // ======================================

                        _campoSenha(
                          controller: _senhaController,
                          labelText: 'Palavra-passe',
                          hintText:
                          'Digite a sua palavra-passe',
                          mostrarSenha: _mostrarSenha,
                          alternarVisibilidade: () {
                            setState(() {
                              _mostrarSenha =
                              !_mostrarSenha;
                            });
                          },
                        ),

                        // Barra de força
                        _barraForcaSenha(),

                        const SizedBox(height: 16),

                        // ======================================
                        // CONFIRMAR PALAVRA-PASSE
                        // ======================================

                        _campoSenha(
                          controller:
                          _confirmarSenhaController,
                          labelText:
                          'Confirmar palavra-passe',
                          hintText:
                          'Repita a sua palavra-passe',
                          mostrarSenha:
                          _mostrarConfirmarSenha,
                          alternarVisibilidade: () {
                            setState(() {
                              _mostrarConfirmarSenha =
                              !_mostrarConfirmarSenha;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // ======================================
                        // BOTÃO CRIAR CONTA
                        // ======================================

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _carregando
                                ? null
                                : _criarConta,
                            style:
                            FilledButton.styleFrom(
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                            child: _carregando
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              'Criar conta',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
