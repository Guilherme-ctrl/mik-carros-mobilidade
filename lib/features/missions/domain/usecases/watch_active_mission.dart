import '../entities/mission.dart';
import '../repositories/missions_repository.dart';

class WatchActiveMission {
  final MissionsRepository _repository;
  WatchActiveMission(this._repository);

  // T10.5 — Stream<Mission?> via Realtime; emits on every DB change to the car's missions
  Stream<Mission?> call(String carId) => _repository.watchActiveMission(carId);
}
