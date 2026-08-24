import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/mission.dart';
import '../repositories/missions_repository.dart';

class WatchActiveMission {
  final MissionsRepository _repository;
  WatchActiveMission(this._repository);

  // T10.5 — Stream<Either<Failure, Mission?>> via Realtime; emits on every
  // DB change to the car's missions. Either-wrapped per the boundary fix
  // (debt #44) — was a raw Stream<Mission?> before this intent.
  Stream<Either<Failure, Mission?>> call(String carId) => _repository.watchActiveMission(carId);
}
