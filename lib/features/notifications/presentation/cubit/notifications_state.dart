import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;

  NotificationsLoaded({required this.notifications});

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  @override
  List<Object?> get props => [notifications];
}
