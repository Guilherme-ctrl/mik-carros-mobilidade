import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/get_my_notifications.dart';
import '../../domain/usecases/mark_as_read.dart';
import '../../domain/usecases/watch_notifications.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetMyNotifications _getMyNotifications;
  final MarkAsRead _markAsRead;
  final WatchNotifications _watchNotifications;
  final LocalNotificationService _localNotifications;

  StreamSubscription<AppNotification?>? _realtimeSub;

  NotificationsCubit(
    this._getMyNotifications,
    this._markAsRead,
    this._watchNotifications,
    this._localNotifications,
  ) : super(NotificationsInitial());

  Future<void> init() async {
    await _localNotifications.init();
    await _loadNotifications();

    _realtimeSub?.cancel();
    _realtimeSub = _watchNotifications().listen((newNotification) {
      // Fire local notification only for newly inserted mission_assigned events
      if (newNotification != null && newNotification.type == 'mission_assigned') {
        _localNotifications.show(newNotification.title, newNotification.body);
      }
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final result = await _getMyNotifications();
    result.fold(
      (_) {},
      (list) => emit(NotificationsLoaded(notifications: list)),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _markAsRead(notificationId);
    await _loadNotifications();
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
