import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/mission.dart';
import '../../domain/entities/reopen_result.dart';
import '../../domain/entities/queue_summary.dart';
import '../../domain/repositories/missions_repository.dart';
import '../datasources/missions_remote_datasource.dart';

class MissionsRepositoryImpl implements MissionsRepository {
  final MissionsRemoteDatasource _datasource;
  MissionsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, String?>> getDriverCarId() async {
    try {
      return Right(await _datasource.getDriverCarId());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Shared by getMissionsForCar/getMissionsHistoryForCar — for each raw
  // request_cars+requests row, fetches the FR3.3 co-assigned roster and
  // merges it in. History entries skip the roster fetch (not displayed
  // there); active ones need it for the shared-mission view.
  Future<List<Mission>> _hydrate(
    List<Map<String, dynamic>> rows,
    String carId, {
    required bool withRoster,
  }) async {
    final missions = <Mission>[];
    for (final row in rows) {
      List<CarSummary> roster = const [];
      if (withRoster) {
        final requestId = (row['requests'] as Map<String, dynamic>)['id'] as String;
        final rosterRows = await _datasource.getCoAssignedCars(requestId, carId);
        roster = rosterRows.map(CarSummary.fromMap).toList();
      }
      missions.add(Mission.fromMap(row, coAssignedCars: roster));
    }
    return missions;
  }

  @override
  Future<Either<Failure, List<Mission>>> getMissionsForCar(String carId) async {
    try {
      final rows = await _datasource.getMissionsForCar(carId);
      return Right(await _hydrate(rows, carId, withRoster: true));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Mission>>> getMissionsHistoryForCar(String carId) async {
    try {
      final rows = await _datasource.getMissionsHistoryForCar(carId);
      return Right(await _hydrate(rows, carId, withRoster: false));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCarStatus(
      String requestId, String carId, String newStatus) async {
    try {
      await _datasource.updateCarStatus(requestId, carId, newStatus);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reportOutcome(
      String requestId, String carId, String outcome) async {
    try {
      await _datasource.reportOutcome(requestId, carId, outcome);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> closeRequest(String requestId) async {
    try {
      await _datasource.closeRequest(requestId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReopenResult>> reopenRequest(String requestId) async {
    try {
      final row = await _datasource.reopenRequest(requestId);
      return Right(ReopenResult.fromMap(row));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // T10.5 — converts the raw change-signal stream into
  // Stream<Either<Failure, Mission?>> (debt #44 fix — no raw Stream crossing
  // the repository boundary).
  @override
  Stream<Either<Failure, Mission?>> watchActiveMission(String carId) {
    final controller = StreamController<Either<Failure, Mission?>>();
    StreamSubscription? sub;

    controller.onListen = () {
      sub = _datasource.watchMissionsForCar(carId).listen(
        (_) async {
          final result = await getMissionsForCar(carId);
          final mapped = result.fold<Either<Failure, Mission?>>(
            (f) => Left(f),
            (list) => Right(list.firstOrNull),
          );
          if (!controller.isClosed) controller.add(mapped);
        },
        onError: (e) {
          if (!controller.isClosed) {
            controller.add(Left(ServerFailure(e.toString())));
          }
        },
      );
    };

    controller.onCancel = () {
      sub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // US4/FR5 — same StreamController shape as watchActiveMission above, with one
  // deliberate difference: it emits an initial value on listen.
  //
  // watchActiveMission can rely on its only consumer (MissionsCubit.init) doing
  // an explicit _loadMissions BEFORE subscribing, so the UI is already populated
  // when the stream is still silent. QueueBadge has no such companion load — it
  // is a StreamBuilder and nothing else. Without the seed emission a driver who
  // opens the app with three missions queued would see NO badge until something
  // happened to change the row, which is precisely the case FR5.3 describes as
  // "opens the active-mission screen, then sees a badge".
  @override
  Stream<Either<Failure, QueueSummary>> watchQueueCount(String carId) {
    final controller = StreamController<Either<Failure, QueueSummary>>();
    StreamSubscription? sub;

    Future<void> emitCurrent() async {
      final result = await _fetchQueueSummary(carId);
      if (!controller.isClosed) controller.add(result);
    }

    controller.onListen = () {
      // Seed (see above). Intentionally not awaited: onListen is synchronous,
      // and the fetch is genuinely async, so the add lands after the listener
      // is attached. Errors cannot escape — _fetchQueueSummary returns Left.
      emitCurrent();

      sub = _datasource.watchQueueCount(carId).listen(
        (_) => emitCurrent(),
        onError: (e) {
          if (!controller.isClosed) {
            controller.add(Left(ServerFailure(e.toString())));
          }
        },
      );
    };

    controller.onCancel = () {
      sub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<Either<Failure, QueueSummary>> _fetchQueueSummary(String carId) async {
    try {
      return Right(QueueSummary.fromMap(await _datasource.getCarQueueSummary(carId)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Comment>>> getComments(String requestId) async {
    try {
      final rows = await _datasource.getComments(requestId);
      return Right(rows.map(Comment.fromMap).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addComment(String requestId, String content) async {
    try {
      await _datasource.addComment(requestId, content);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<void> watchComments(String requestId) => _datasource.watchComments(requestId);
}
