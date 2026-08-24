import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/queue_summary.dart';
import '../repositories/missions_repository.dart';

class WatchQueueCount {
  final MissionsRepository _repository;
  WatchQueueCount(this._repository);

  // US4/FR5 — Stream<Either<Failure, QueueSummary>> via Realtime; emits on every
  // change to this car's assignments. Same shape and layering as
  // WatchActiveMission: the usecase only delegates, so the reduced projection
  // (FILA-ADR-5) is enforced in exactly one place — the RPC the repository
  // calls — and cannot be widened from here.
  Stream<Either<Failure, QueueSummary>> call(String carId) =>
      _repository.watchQueueCount(carId);
}
