import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_session.dart';

abstract class AuthRemoteDatasource {
  Future<UserSession> signIn({required String email, required String password});
  Future<void> signOut();
  Future<UserSession?> getCurrentSession();
  Future<void> updatePushToken(String token);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient _client;
  AuthRemoteDatasourceImpl() : _client = Supabase.instance.client;

  @override
  Future<UserSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw const AuthException('Login falhou');
    return _sessionForUser(user);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<UserSession?> getCurrentSession() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    return _sessionForUser(session.user);
  }

  @override
  Future<void> updatePushToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('push_tokens').upsert({
      'user_id': userId,
      'push_token': token,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<UserSession> _sessionForUser(User user) async {
    final row = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      throw const AuthException(
        'Acesso não configurado. Contate a Mesa Central.',
      );
    }

    return UserSession(
      id: user.id,
      email: user.email ?? '',
      role: row['role'] as String,
    );
  }
}
