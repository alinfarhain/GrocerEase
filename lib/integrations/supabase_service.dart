import 'package:supabase_flutter/supabase_flutter.dart';
import '../globals/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  factory SupabaseService() {
    return _instance;
  }

  static final SupabaseService _instance = SupabaseService._();

  Future initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<AuthResponse> signUp(
      String email,
      String password, {
        Map<String, dynamic>? data,
        String? emailRedirectTo,
      }) async {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: data,
      emailRedirectTo: emailRedirectTo,
    );
  }
}
