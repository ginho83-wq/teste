import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final AuthService instancia = AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // USUÁRIO ATUAL
  // ============================================================

  User? get usuarioAtual {
    return _supabase.auth.currentUser;
  }

  // ============================================================
  // EVENTOS DE AUTENTICAÇÃO
  // ============================================================

  Stream<AuthState> get eventosAuth {
    return _supabase.auth.onAuthStateChange;
  }

  // ============================================================
  // LOGIN COM EMAIL E PALAVRA-PASSE
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
  // CRIAR CONTA
  // ============================================================

  Future<void> criarConta({
    required String email,
    required String senha,
  }) async {
    await _supabase.auth.signUp(
      email: email.trim(),
      password: senha,
      emailRedirectTo: '${Uri.base.origin}/auth/callback',
    );
  }

  // ============================================================
  // LOGIN COM GOOGLE
  // ============================================================

  Future<void> entrarComGoogle() async {
    final origin = Uri.base.origin;

    final redirectUrl = '$origin/auth/callback';

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  // ============================================================
  // SAIR
  // ============================================================

  Future<void> sair() async {
    await _supabase.auth.signOut();
  }
}

