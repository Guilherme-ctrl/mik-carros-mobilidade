import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class GetMyNotifications {
  final NotificationsRepository _repository;
  GetMyNotifications(this._repository);

  Future<Either<Failure, List<AppNotification>>> call() =>
      _repository.getMyNotifications();
}
