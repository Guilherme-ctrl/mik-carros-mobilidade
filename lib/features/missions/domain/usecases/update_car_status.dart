import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/missions_repository.dart';

// Replaces UpdateMissionStatus (ADR-3 — per-car progress transitions move to
// update_car_status; request-level transitions stay on update_request_status,
// which this app never called for progress steps anyway).
class UpdateCarStatus {
  final MissionsRepository _repository;
  UpdateCarStatus(this._repository);

  Future<Either<Failure, void>> call(String requestId, String carId, String newStatus) =>
      _repository.updateCarStatus(requestId, carId, newStatus);
}
