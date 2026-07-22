import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/location_service.dart';

class StartLocationTracking {
  final LocationService _service;
  StartLocationTracking(this._service);

  Future<void> call() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'StartLocationTracking: no current user',
        category: 'location',
        level: SentryLevel.warning,
      ));
      return;
    }

    // ignore: avoid_print
    print('[StartLocationTracking] client user.id=${user.id}');
    Sentry.addBreadcrumb(Breadcrumb(
      message: 'StartLocationTracking: user=${user.id} email=${user.email}',
      category: 'location',
      level: SentryLevel.info,
    ));

    // Check what auth.uid() returns server-side
    try {
      final uidResult = await Supabase.instance.client.rpc('debug_auth_uid');
      // ignore: avoid_print
      print('[StartLocationTracking] server auth.uid()=$uidResult');
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'StartLocationTracking: server auth.uid()=$uidResult',
        category: 'location',
        level: SentryLevel.info,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[StartLocationTracking] debug_auth_uid not available: $e');
    }

    try {
      final row = await Supabase.instance.client
          .from('cars')
          .select('id, driver_user_id')
          .eq('driver_user_id', user.id)
          .maybeSingle();

      // ignore: avoid_print
      print('[StartLocationTracking] car row=$row');

      if (row == null) {
        await Sentry.captureMessage(
          'StartLocationTracking: no car found for user ${user.id} (${user.email})',
          level: SentryLevel.error,
        );
        return;
      }

      Sentry.addBreadcrumb(Breadcrumb(
        message: 'StartLocationTracking: found car ${row['id']}',
        category: 'location',
        level: SentryLevel.info,
      ));

      await _service.startTracking(row['id'] as String);
    } catch (e, s) {
      // ignore: avoid_print
      print('[StartLocationTracking] error: $e');
      await Sentry.captureException(e, stackTrace: s, withScope: (scope) {
        scope.setTag('component', 'start_location_tracking');
        scope.setTag('user_id', user.id);
      });
    }
  }
}
