import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instancia = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;
}
