import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MissionsRemoteDatasource {
  Future<String?> getDriverCarId();
  Future<List<Map<String, dynamic>>> getMissionsForCar(String carId);
  Future<void> updateMissionStatus(String requestId, String newStatus);
  // Emits null whenever a DB change occurs — cubit uses it as a reload trigger
  Stream<void> watchMissionsForCar(String carId);

  Future<List<Map<String, dynamic>>> getComments(String requestId);
  Future<void> addComment(String requestId, String content);
  Stream<void> watchComments(String requestId);
}

class MissionsRemoteDatasourceImpl implements MissionsRemoteDatasource {
  final SupabaseClient _client;
  MissionsRemoteDatasourceImpl() : _client = Supabase.instance.client;

  // T10.16 — cache key scoped per user so multi-driver devices work correctly
  String _prefKey(String userId) => 'driver_car_id_$userId';

  @override
  Future<String?> getDriverCarId() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefKey(user.id));
    if (cached != null) return cached;

    final row = await _client
        .from('cars')
        .select('id')
        .eq('driver_user_id', user.id)
        .maybeSingle();

    if (row == null) return null;
    final carId = row['id'] as String;
    await prefs.setString(_prefKey(user.id), carId);
    return carId;
  }

  @override
  Future<List<Map<String, dynamic>>> getMissionsForCar(String carId) async {
    // T10.8 — join leaders for name + phone display in the card
    final rows = await _client
        .from('requests')
        .select('*, leaders(name, phone)')
        .eq('assigned_car_id', carId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<void> updateMissionStatus(String requestId, String newStatus) async {
    await _client.rpc('update_request_status', params: {
      'p_request_id': requestId,
      'p_new_status': newStatus,
    });
  }

  @override
  Stream<void> watchMissionsForCar(String carId) {
    // T10.15 — Realtime filtered by assigned_car_id; catches new assignments too
    final controller = StreamController<void>.broadcast();
    RealtimeChannel? channel;

    channel = _client
        .channel('driver-missions-$carId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'assigned_car_id',
            value: carId,
          ),
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();

    controller.onCancel = () async {
      if (channel != null) await _client.removeChannel(channel);
      await controller.close();
    };

    return controller.stream;
  }

  @override
  Future<List<Map<String, dynamic>>> getComments(String requestId) async {
    final rows = await _client
        .from('request_comments')
        .select('id, request_id, author_id, author_name, content, created_at')
        .eq('request_id', requestId)
        .order('created_at', ascending: true)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<void> addComment(String requestId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Não autenticado');
    await _client.from('request_comments').insert({
      'request_id': requestId,
      'author_id': user.id,
      'content': content,
    });
  }

  @override
  Stream<void> watchComments(String requestId) {
    final controller = StreamController<void>.broadcast();
    RealtimeChannel? channel;

    channel = _client
        .channel('comments-$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'request_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: requestId,
          ),
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
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
