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
      await AuthService.instancia.entrarComGoogle();

      // O Google redireciona para /auth/callback.
      // O GoRouter trata a sessão e encaminha para a Home.
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
  // RECUPERAR PALAVRA-PASSE
  // ============================================================

  Future<void> _recuperarPalavraPasse() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        bool enviando = false;

        return StatefulBuilder(
          builder: (
              context,
              setStateDialog,
              ) {
            return AlertDialog(
              title: const Text(
                'Recuperar palavra-passe',
              ),
              content: SizedBox(
                width: 380,
                child: TextField(
                  controller: emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  autofocus: true,
                  enabled: !enviando,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText:
                    'Digite o email da sua conta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: enviando
                      ? null
                      : () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton(
                  onPressed: enviando
                      ? null
                      : () async {
                    final email =
                    emailController.text.trim();

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Informe o seu email.',
                          ),
                        ),
                      );
                      return;
                    }

                    setStateDialog(() {
                      enviando = true;
                    });

                    try {
                      await AuthService
                          .instancia
                          .recuperarPalavraPasse(
                        email: email,
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.of(
                        dialogContext,
                      ).pop(email);
                    } on AuthException catch (e) {
                      setStateDialog(() {
                        enviando = false;
                      });

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.message,
                          ),
                        ),
                      );
                    } catch (e) {
                      setStateDialog(() {
                        enviando = false;
                      });

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erro ao enviar o email: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: enviando
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Enviar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();

    if (!mounted || email == null) {
      return;
    }

    _mostrarMensagem(
      'Enviámos um link de recuperação para $email. '
          'Verifique o seu email.',
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );
  }

  // ============================================================
  // FORMULÁRIO DE LOGIN
  // ============================================================

  Widget _buildFormularioLogin(
      ThemeData theme,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ======================================================
        // EMAIL
        // ======================================================

        TextField(
          controller: _emailController,
          keyboardType:
          TextInputType.emailAddress,
          textInputAction:
          TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.email_outlined,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ======================================================
        // PALAVRA-PASSE
        // ======================================================

        TextField(
          controller: _senhaController,
          obscureText: !_mostrarSenha,
          textInputAction:
          TextInputAction.done,
          onSubmitted: (_) {
            if (!_carregando) {
              _entrar();
            }
          },
          decoration: InputDecoration(
            labelText: 'Palavra-passe',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(
              Icons.lock_outline,
            ),
            suffixIcon: IconButton(
              onPressed: _carregando
                  ? null
                  : () {
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

        // ======================================================
        // ESQUECEU A PALAVRA-PASSE?
        // ======================================================

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _carregando
                ? null
                : _recuperarPalavraPasse,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Esqueceu a palavra-passe?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ======================================================
        // BOTÃO ENTRAR
        // ======================================================

        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed:
            _carregando ? null : _entrar,
            child: _carregando
                ? const SizedBox(
              width: 22,
              height: 22,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Text('Entrar'),
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // GOOGLE
        // ======================================================

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
      ],
    );
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // NOME DO SITE — CANTO SUPERIOR ESQUERDO
            // ==================================================

            Positioned(
              top: 16,
              left: 20,
              child: Text(
                'Teste',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                  theme.colorScheme.onSurface,
                ),
              ),
            ),

            // ==================================================
            // CONTEÚDO CENTRAL
            // ==================================================

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 80,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // TÍTULO
                      // ==================================================

                      Text(
                        'Entrar',
                        style: theme
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Aceda à sua conta',
                        style: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color:
                          Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // FORMULÁRIO
                      // ==================================================

                      _buildFormularioLogin(theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
}
