import 'dart:async';

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

  StreamSubscription<AuthState>? _subscription;

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
      final auth = Supabase.instance.client.auth;

      // ========================================================
      // 1. VERIFICAR SE A SESSÃO JÁ FOI CRIADA
      // ========================================================

      if (auth.currentSession != null) {
        if (!mounted) return;

        context.go('/');
        return;
      }

      // ========================================================
      // 2. AGUARDAR O SUPABASE CONCLUIR A AUTENTICAÇÃO
      // ========================================================

      final completer = Completer<Session?>();

      _subscription = auth.onAuthStateChange.listen((data) {
        final session = data.session;

        if (session != null && !completer.isCompleted) {
          completer.complete(session);
        }
      });

      // ========================================================
      // 3. AGUARDAR A SESSÃO
      // ========================================================

      final session = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      // ========================================================
      // 4. CANCELAR LISTENER
      // ========================================================

      await _subscription?.cancel();
      _subscription = null;

      // ========================================================
      // 5. CONFIRMAR SESSÃO
      // ========================================================

      if (session == null) {
        throw Exception(
          'Não foi possível concluir a autenticação.',
        );
      }

      // ========================================================
      // 6. IR PARA HOME
      // ========================================================

      if (!mounted) return;

      context.go('/');
    } catch (e) {
      await _subscription?.cancel();
      _subscription = null;

      if (!mounted) return;

      setState(() {
        _erro = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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

