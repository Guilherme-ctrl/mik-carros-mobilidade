import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationsRemoteDatasource {
  Future<List<Map<String, dynamic>>> getMyNotifications();
  Future<void> markAsRead(String notificationId);
  Stream<AppNotification?> watchMyNotifications();
}

class NotificationsRemoteDatasourceImpl implements NotificationsRemoteDatasource {
  final SupabaseClient _client;
  NotificationsRemoteDatasourceImpl() : _client = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId);
  }

  @override
  Stream<AppNotification?> watchMyNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    final controller = StreamController<AppNotification?>.broadcast();
    RealtimeChannel? channel;

    channel = _client
        .channel('notifications-mobile-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (controller.isClosed) return;
            // On INSERT emit the new row so the cubit can fire a local notification
            if (payload.eventType == PostgresChangeEvent.insert) {
              controller.add(AppNotification.fromMap(payload.newRecord));
            } else {
              controller.add(null);
            }
          },
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }
}
