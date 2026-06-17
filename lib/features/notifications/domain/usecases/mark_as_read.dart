import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/notifications_repository.dart';

class MarkAsRead {
  final NotificationsRepository _repository;
  MarkAsRead(this._repository);

  Future<Either<Failure, void>> call(String notificationId) =>
      _repository.markAsRead(notificationId);
}
