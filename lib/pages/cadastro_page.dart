import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() =>
      _CadastroPageState();
}

class _CadastroPageState
    extends State<CadastroPage> {
  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _senhaController =
  TextEditingController();

  final TextEditingController
  _confirmarSenhaController =
  TextEditingController();

  bool _carregando = false;

  Future<void> _criarConta() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmarSenha =
        _confirmarSenhaController.text;

    if (email.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      _mostrarMensagem(
        'Preencha todos os campos.',
      );
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
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar conta'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 420,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),

                const Icon(
                  Icons.person_add_outlined,
                  size: 70,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Criar conta',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: _emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon:
                    Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Palavra-passe',
                    border: OutlineInputBorder(),
                    prefixIcon:
                    Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller:
                  _confirmarSenhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText:
                    'Confirmar palavra-passe',
                    border: OutlineInputBorder(),
                    prefixIcon:
                    Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _carregando
                        ? null
                        : _criarConta,
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
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _carregando
                      ? null
                      : () {
                    context.go('/login');
                  },
                  child: const Text(
                    'Já tenho uma conta',
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
