import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository _repository;
  SignInWithEmail(this._repository);

  Future<Either<Failure, UserSession>> call(String email, String password) {
    return _repository.signIn(email: email, password: password);
  }
}
