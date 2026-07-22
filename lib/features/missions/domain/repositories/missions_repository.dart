import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/comment.dart';
import '../entities/mission.dart';

abstract class MissionsRepository {
  Future<Either<Failure, String?>> getDriverCarId();
  Future<Either<Failure, List<Mission>>> getMissionsForCar(String carId);
  Future<Either<Failure, void>> updateMissionStatus(String requestId, String newStatus);
  Future<Either<Failure, void>> setOutcomeNotFound(String requestId);
  Future<Either<Failure, void>> setOutcomeFound(String requestId);
  // T10.5 — stream emits the current active mission whenever it changes
  Stream<Mission?> watchActiveMission(String carId);

  Future<Either<Failure, List<Comment>>> getComments(String requestId);
  Future<Either<Failure, void>> addComment(String requestId, String content);
  Stream<void> watchComments(String requestId);
}
