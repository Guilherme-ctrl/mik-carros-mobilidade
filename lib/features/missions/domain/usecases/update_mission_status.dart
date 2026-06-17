import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/missions_repository.dart';

class UpdateMissionStatus {
  final MissionsRepository _repository;
  UpdateMissionStatus(this._repository);

  // T10.4 — calls RPC update_request_status
  Future<Either<Failure, void>> call(String requestId, String newStatus) =>
      _repository.updateMissionStatus(requestId, newStatus);
}
