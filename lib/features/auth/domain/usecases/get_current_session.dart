import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/user_session.dart';
import '../repositories/auth_repository.dart';

class GetCurrentSession {
  final AuthRepository _repository;
  GetCurrentSession(this._repository);

  Future<Either<Failure, UserSession?>> call() {
    return _repository.getCurrentSession();
  }
}
