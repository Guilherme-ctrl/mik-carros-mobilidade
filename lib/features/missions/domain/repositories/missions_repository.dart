import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/comment.dart';
import '../entities/mission.dart';
import '../entities/reopen_result.dart';
import '../entities/queue_summary.dart';

abstract class MissionsRepository {
  Future<Either<Failure, String?>> getDriverCarId();
  Future<Either<Failure, List<Mission>>> getMissionsForCar(String carId);
  Future<Either<Failure, List<Mission>>> getMissionsHistoryForCar(String carId);
  Future<Either<Failure, void>> updateCarStatus(String requestId, String carId, String newStatus);
  Future<Either<Failure, void>> reportOutcome(String requestId, String carId, String outcome);
  Future<Either<Failure, void>> closeRequest(String requestId);
  Future<Either<Failure, ReopenResult>> reopenRequest(String requestId);
  // T10.5 — stream emits the current active mission whenever it changes.
  // Returns Either (not a raw Stream<Mission?>) — the boundary rule
  // (team.md § Code Style) applies to streams too; the old raw-Stream
  // signature was a pre-existing violation, fixed here as part of this
  // change (debt item #44).
  Stream<Either<Failure, Mission?>> watchActiveMission(String carId);

  // US4/FR5 — the car's queue count + minimal per-item summary, re-emitted on
  // every Realtime change. Either-wrapped for the same boundary rule as
  // watchActiveMission above: a raw Stream would leave the presentation layer
  // with no way to distinguish "no queue" from "the read failed".
  Stream<Either<Failure, QueueSummary>> watchQueueCount(String carId);

  Future<Either<Failure, List<Comment>>> getComments(String requestId);
  Future<Either<Failure, void>> addComment(String requestId, String content);
  Stream<void> watchComments(String requestId);
}
