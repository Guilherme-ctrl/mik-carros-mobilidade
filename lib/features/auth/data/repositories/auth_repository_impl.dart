import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  AuthRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, UserSession>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _datasource.signIn(email: email, password: password);
      return Right(session);
    } on AuthException catch (e) {
      if (e.message.contains('Acesso não configurado')) {
        return Left(UnauthorizedFailure(e.message));
      }
      final msg = _translateAuthError(e.message);
      return Left(AuthFailure(msg));
    } catch (_) {
      return Left(const AuthFailure('Erro inesperado. Tente novamente.'));
    }
  }

  String _translateAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid email or password')) {
      return 'Email ou senha incorretos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email não confirmado. Contate a Mesa Central.';
    }
    if (lower.contains('user not found')) {
      return 'Usuário não encontrado.';
    }
    if (lower.contains('banned') || lower.contains('user is disabled')) {
      return 'Conta inativa. Contate a Mesa Central.';
    }
    return raw;
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } catch (_) {
      return Left(const AuthFailure('Erro ao sair.'));
    }
  }

  @override
  Future<Either<Failure, UserSession?>> getCurrentSession() async {
    try {
      final session = await _datasource.getCurrentSession();
      return Right(session);
    } catch (_) {
      return Left(const AuthFailure('Erro ao verificar sessão.'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePushToken(String token) async {
    try {
      await _datasource.updatePushToken(token);
      return const Right(null);
    } catch (_) {
      return Left(const ServerFailure('Erro ao salvar token de notificação.'));
    }
  }
}
