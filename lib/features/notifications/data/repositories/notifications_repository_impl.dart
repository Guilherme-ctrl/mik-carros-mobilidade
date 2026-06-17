import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDatasource _datasource;
  NotificationsRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<AppNotification>>> getMyNotifications() async {
    try {
      final rows = await _datasource.getMyNotifications();
      return Right(rows.map(AppNotification.fromMap).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await _datasource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<AppNotification?> watchMyNotifications() =>
      _datasource.watchMyNotifications();
}
