import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class WatchNotifications {
  final NotificationsRepository _repository;
  WatchNotifications(this._repository);

  Stream<AppNotification?> call() => _repository.watchMyNotifications();
}
