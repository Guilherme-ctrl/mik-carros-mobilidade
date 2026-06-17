import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_session.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserSession>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserSession?>> getCurrentSession();
}
