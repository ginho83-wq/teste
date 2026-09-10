import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ============================================================
  // CONTROLADORES
  // ============================================================

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _senhaController =
  TextEditingController();

  // ============================================================
  // ESTADO
  // ============================================================

  bool _carregando = false;
  bool _mostrarSenha = false;

  // ============================================================
  // LOGIN COM EMAIL E PALAVRA-PASSE
  // ============================================================

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mostrarMensagem(
        'Preencha o email e a palavra-passe.',
      );
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await AuthService.instancia.entrarComEmail(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      context.go('/');
    } on AuthException catch (e) {
      _mostrarMensagem(e.message);
    } catch (e) {
      _mostrarMensagem('Erro ao entrar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // LOGIN COM GOOGLE
  // ============================================================

  Future<void> _entrarGoogle() async {
    setState(() {
      _carregando = true;
    });

    try {
      await AuthService.instancia.entrarComGoogle();

      // O Google redireciona para /auth/callback.
      // O GoRouter trata a sessão e encaminha para /home.
    } on AuthException catch (e) {
      _mostrarMensagem(e.message);

      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    } catch (e) {
      _mostrarMensagem(
        'Erro ao entrar com Google: $e',
      );

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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // NOME DO WEB — CANTO SUPERIOR ESQUERDO
            // ==================================================

            Positioned(
              top: 16,
              left: 20,
              child: Text(
                'Teste',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
              ),
            ),

            // ==================================================
            // CRIAR CONTA — CANTO SUPERIOR DIREITO
            // ==================================================

            Positioned(
              top: 16,
              right: 20,
              child: TextButton(
                onPressed: _carregando
                    ? null
                    : () {
                  context.go('/cadastro');
                },
                child: const Text(
                  'Criar conta',
                ),
              ),
            ),

            // ==================================================
            // FORMULÁRIO CENTRAL
            // ==================================================

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: ScrollConfiguration(
                  behavior:
                  ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==================================================
                        // EMAIL
                        // ==================================================

                        TextField(
                          controller: _emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // PALAVRA-PASSE
                        // ==================================================

                        TextField(
                          controller: _senhaController,
                          obscureText: !_mostrarSenha,
                          decoration: InputDecoration(
                            labelText: 'Palavra-passe',
                            border:
                            const OutlineInputBorder(),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _mostrarSenha =
                                  !_mostrarSenha;
                                });
                              },
                              icon: Icon(
                                _mostrarSenha
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // BOTÃO ENTRAR
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _carregando
                                ? null
                                : _entrar,
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
                              'Entrar',
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // SEPARADOR
                        // ==================================================

                        Row(
                          children: [
                            const Expanded(
                              child: Divider(),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'ou',
                                style: TextStyle(
                                  color:
                                  Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // GOOGLE
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _carregando
                                ? null
                                : _entrarGoogle,
                            icon: const Icon(
                              Icons.login,
                            ),
                            label: const Text(
                              'Continuar com Google',
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
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


