import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../constants/app_constants.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception(ErrorMessages.invalidCredentials);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception(ErrorMessages.serverError);
    }
  }

  Future<UserProfile> getCurrentUserProfile() async {
    if (_supabase.auth.currentUser == null) {
      throw Exception(ErrorMessages.unauthorized);
    }

    try {
      final response = await _supabase
          .from(AppTables.profiles)
          .select()
          .eq('id', _supabase.auth.currentUser!.id)
          .single();

      return UserProfile.fromJson({
        ...response as Map<String, dynamic>,
        'email': _supabase.auth.currentUser!.email,
      });
    } catch (e) {
      throw Exception(ErrorMessages.noUserProfile);
    }
  }

  bool get isAuthenticated => _supabase.auth.currentUser != null;
  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;
}