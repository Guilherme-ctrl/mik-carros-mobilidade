import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/location_service.dart';

class StartLocationTracking {
  final LocationService _service;
  StartLocationTracking(this._service);

  Future<void> call() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // ignore: avoid_print
    print('[StartLocationTracking] client user.id=${user.id}');

    // Check what auth.uid() returns server-side
    try {
      final uidResult = await Supabase.instance.client.rpc('debug_auth_uid');
      // ignore: avoid_print
      print('[StartLocationTracking] server auth.uid()=$uidResult');
    } catch (e) {
      // ignore: avoid_print
      print('[StartLocationTracking] debug_auth_uid not available: $e');
    }

    final row = await Supabase.instance.client
        .from('cars')
        .select('id, driver_user_id')
        .eq('driver_user_id', user.id)
        .maybeSingle();

    // ignore: avoid_print
    print('[StartLocationTracking] car row=$row');

    if (row == null) return;
    await _service.startTracking(row['id'] as String);
  }
}
