import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/missions_repository.dart';

class SetOutcomeFound {
  final MissionsRepository _repository;
  SetOutcomeFound(this._repository);

  Future<Either<Failure, void>> call(String requestId) =>
      _repository.setOutcomeFound(requestId);
}
