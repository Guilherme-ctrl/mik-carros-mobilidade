import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/mission.dart';
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

  @override
  Future<Either<Failure, List<Mission>>> getMissionsForCar(String carId) async {
    try {
      final rows = await _datasource.getMissionsForCar(carId);
      return Right(rows.map(Mission.fromMap).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMissionStatus(
      String requestId, String newStatus) async {
    try {
      await _datasource.updateMissionStatus(requestId, newStatus);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // T10.5 — converts the raw change-signal stream into Stream<Mission?>
  @override
  Stream<Mission?> watchActiveMission(String carId) {
    final controller = StreamController<Mission?>();
    StreamSubscription? sub;

    controller.onListen = () {
      sub = _datasource.watchMissionsForCar(carId).listen(
        (_) async {
          final result = await getMissionsForCar(carId);
          final active = result.fold(
            (_) => null,
            (list) => list.where((m) => m.status.isActive).firstOrNull,
          );
          if (!controller.isClosed) controller.add(active);
        },
        onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        },
      );
    };

    controller.onCancel = () {
      sub?.cancel();
      controller.close();
    };

    return controller.stream;
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
