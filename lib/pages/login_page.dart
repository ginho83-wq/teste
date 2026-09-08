import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {
  // ============================================================
  // CONTROLADORES
  // ============================================================

  final TextEditingController
  _emailController =
  TextEditingController();

  final TextEditingController
  _senhaController =
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
    final email =
    _emailController.text.trim();

    final senha =
        _senhaController.text;

    if (email.isEmpty ||
        senha.isEmpty) {
      _mostrarMensagem(
        'Preencha o email e a palavra-passe.',
      );

      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      await AuthService.instancia
          .entrarComEmail(
        email: email,
        senha: senha,
      );

      if (!mounted) return;

      // ========================================================
      // LOGIN CONCLUÍDO
      // ========================================================

      context.go('/home');
    } on AuthException catch (e) {
      _mostrarMensagem(
        e.message,
      );
    } catch (e) {
      _mostrarMensagem(
        'Erro ao entrar: $e',
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
  // LOGIN COM GOOGLE
  // ============================================================

  Future<void> _entrarGoogle() async {
    setState(() {
      _carregando = true;
    });

    try {
      await AuthService.instancia
          .entrarComGoogle();

      // ========================================================
      // NÃO FAZEMOS context.go('/home') AQUI.
      //
      // O Google abre a autenticação.
      // Depois retorna para /auth/callback.
      // O GoRouter detecta a sessão e manda para /home.
      // ========================================================
    } on AuthException catch (e) {
      _mostrarMensagem(
        e.message,
      );

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

  void _mostrarMensagem(
      String mensagem,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
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
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrar',
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 420,
          ),

          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,

              children: [
                const SizedBox(
                  height: 60,
                ),

                // ==================================================
                // ÍCONE
                // ==================================================

                const Icon(
                  Icons.lock_outline,
                  size: 70,
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // TÍTULO
                // ==================================================

                const Text(
                  'Entrar',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                // ==================================================
                // EMAIL
                // ==================================================

                TextField(
                  controller:
                  _emailController,

                  keyboardType:
                  TextInputType
                      .emailAddress,

                  decoration:
                  const InputDecoration(
                    labelText:
                    'Email',

                    border:
                    OutlineInputBorder(),

                    prefixIcon:
                    Icon(
                      Icons
                          .email_outlined,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // PALAVRA-PASSE
                // ==================================================

                TextField(
                  controller:
                  _senhaController,

                  obscureText:
                  !_mostrarSenha,

                  decoration:
                  InputDecoration(
                    labelText:
                    'Palavra-passe',

                    border:
                    const OutlineInputBorder(),

                    prefixIcon:
                    const Icon(
                      Icons
                          .lock_outline,
                    ),

                    suffixIcon:
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _mostrarSenha =
                          !_mostrarSenha;
                        });
                      },

                      icon: Icon(
                        _mostrarSenha
                            ? Icons
                            .visibility_off
                            : Icons
                            .visibility,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // BOTÃO ENTRAR
                // ==================================================

                SizedBox(
                  width:
                  double.infinity,

                  height: 48,

                  child:
                  FilledButton(
                    onPressed:
                    _carregando
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

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // BOTÃO GOOGLE
                // ==================================================

                SizedBox(
                  width:
                  double.infinity,

                  height: 48,

                  child:
                  OutlinedButton.icon(
                    onPressed:
                    _carregando
                        ? null
                        : _entrarGoogle,

                    icon:
                    const Icon(
                      Icons.login,
                    ),

                    label:
                    const Text(
                      'Continuar com Google',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // CADASTRO
                // ==================================================

                TextButton(
                  onPressed:
                  _carregando
                      ? null
                      : () {
                    context.go(
                      '/cadastro',
                    );
                  },

                  child:
                  const Text(
                    'Criar uma conta',
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


