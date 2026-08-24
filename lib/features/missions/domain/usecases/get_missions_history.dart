import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/mission.dart';
import '../repositories/missions_repository.dart';

class GetMissionsHistory {
  final MissionsRepository _repository;
  GetMissionsHistory(this._repository);

  Future<Either<Failure, List<Mission>>> call(String carId) =>
      _repository.getMissionsHistoryForCar(carId);
}
