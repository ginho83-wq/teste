import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthCallbackPage extends StatefulWidget {
  const AuthCallbackPage({
    super.key,
  });

  @override
  State<AuthCallbackPage> createState() =>
      _AuthCallbackPageState();
}

class _AuthCallbackPageState
    extends State<AuthCallbackPage> {

  String? _erro;

  @override
  void initState() {
    super.initState();

    _processarCallback();
  }

  // ============================================================
  // PROCESSAR CALLBACK
  // ============================================================

  Future<void> _processarCallback() async {
    try {
      final uri = Uri.base;

      // ========================================================
      // OBTER O CODE DEVOLVIDO PELO GOOGLE/SUPABASE
      // ========================================================

      final code = uri.queryParameters['code'];

      if (code == null || code.isEmpty) {
        throw Exception(
          'Código de autenticação não encontrado.',
        );
      }

      // ========================================================
      // TROCAR O CODE POR UMA SESSÃO
      // ========================================================

      await Supabase.instance.client.auth
          .exchangeCodeForSession(code);

      // ========================================================
      // VERIFICAR SESSÃO
      // ========================================================

      final session =
          Supabase.instance.client.auth.currentSession;

      if (session == null) {
        throw Exception(
          'Não foi possível criar a sessão.',
        );
      }

      // ========================================================
      // IR PARA HOME
      // ========================================================

      if (!mounted) return;

      context.go('/');

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = e.toString();
      });
    }
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Erro de autenticação',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Não foi possível concluir o login.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _erro!,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: const Text(
                    'Voltar ao login',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),

            SizedBox(height: 20),

            Text(
              'A entrar com Google...',
            ),
          ],
        ),
      ),
    );
  }
}

