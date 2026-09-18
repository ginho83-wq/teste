import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final AuthService instancia = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // URL DE CALLBACK
  // ============================================================

  String get _redirectUrl {
    if (kIsWeb) {
      final String host = Uri.base.host;

      // Ambiente local
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:3000/auth/callback';
      }
    }

    // Ambiente de produção — GitHub Pages
    return 'https://ginho83-wq.github.io/teste/auth/callback';
  }

  // ============================================================
  // USUÁRIO ATUAL
  // ============================================================

  User? get usuarioAtual {
    return _supabase.auth.currentUser;
  }

  // ============================================================
  // ESTADO DE AUTENTICAÇÃO
  // ============================================================

  bool get estaAutenticado {
    return usuarioAtual != null;
  }

  // ============================================================
  // EVENTOS DE AUTENTICAÇÃO
  // ============================================================

  Stream<AuthState> get eventosAuth {
    return _supabase.auth.onAuthStateChange;
  }

  // ============================================================
  // LOGIN COM EMAIL
  // ============================================================

  Future<void> entrarComEmail({
    required String email,
    required String senha,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: senha,
    );
  }

  // ============================================================
  // RECUPERAR PALAVRA-PASSE
  // ============================================================

  Future<void> recuperarPalavraPasse({
    required String email,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _redirectUrl,
    );
  }

  // ============================================================
  // CRIAR CONTA
  // ============================================================

  Future<void> criarConta({
    required String email,
    required String senha,
  }) async {
    await _supabase.auth.signUp(
      email: email.trim(),
      password: senha,
      emailRedirectTo: _redirectUrl,
    );
  }

  // ============================================================
  // LOGIN COM GOOGLE
  // ============================================================

  Future<void> entrarComGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
    );
  }

  // ============================================================
  // OBTER PERFIL
  // ============================================================

  Future<Map<String, dynamic>?> obterPerfil() async {
    final usuario = usuarioAtual;

    if (usuario == null) {
      return null;
    }

    final resposta = await _supabase
        .from('profiles')
        .select()
        .eq('id', usuario.id)
        .maybeSingle();

    return resposta;
  }

  // ============================================================
  // VERIFICAR ADMINISTRADOR
  // ============================================================

  Future<bool> ehAdmin() async {
    final perfil = await obterPerfil();

    if (perfil == null) {
      return false;
    }

    return perfil['role'] == 'admin';
  }

  // ============================================================
  // COMPATIBILIDADE
  // ============================================================

  Future<bool> ehAdministrador() async {
    return ehAdmin();
  }

  // ============================================================
  // SAIR
  // ============================================================

  Future<void> sair() async {
    await _supabase.auth.signOut();
  }
}
