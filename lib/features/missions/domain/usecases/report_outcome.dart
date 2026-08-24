import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/missions_repository.dart';

// Replaces SetOutcomeFound + SetOutcomeNotFound — ADR-7 made outcome
// reporting symmetric for both values via a single RPC (report_car_outcome).
class ReportOutcome {
  final MissionsRepository _repository;
  ReportOutcome(this._repository);

  Future<Either<Failure, void>> call(String requestId, String carId, String outcome) =>
      _repository.reportOutcome(requestId, carId, outcome);
}
