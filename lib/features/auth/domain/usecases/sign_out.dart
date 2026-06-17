import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  final AuthRepository _repository;
  SignOut(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.signOut();
  }
}
