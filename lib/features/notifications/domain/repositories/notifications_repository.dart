import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<AppNotification>>> getMyNotifications();
  Future<Either<Failure, void>> markAsRead(String notificationId);
  // Emits the inserted AppNotification on INSERT, null on UPDATE/DELETE
  Stream<AppNotification?> watchMyNotifications();
}
