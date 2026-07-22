import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

class UpdatePushToken {
  final AuthRepository _repository;
  UpdatePushToken(this._repository);

  Future<Either<Failure, void>> call(String token) =>
      _repository.updatePushToken(token);
}
