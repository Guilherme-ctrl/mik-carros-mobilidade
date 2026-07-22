import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/missions_repository.dart';

class SetOutcomeNotFound {
  final MissionsRepository _repository;
  SetOutcomeNotFound(this._repository);

  Future<Either<Failure, void>> call(String requestId) =>
      _repository.setOutcomeNotFound(requestId);
}
