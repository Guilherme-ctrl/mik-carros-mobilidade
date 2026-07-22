import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  Timer? _timer;
  String? _carId;

  final _permissionDeniedController = StreamController<bool>.broadcast();
  bool _permissionDenied = false;

  Stream<bool> get permissionDeniedStream => _permissionDeniedController.stream;
  bool get permissionDenied => _permissionDenied;

  Future<void> startTracking(String carId) async {
    _carId = carId;
    _timer?.cancel();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _permissionDenied = true;
      _permissionDeniedController.add(true);
      // ignore: avoid_print
      print('[LocationService] location services disabled');
      return;
    }

    final permission = await Geolocator.requestPermission();
    final denied = permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever;
    _permissionDenied = denied;
    _permissionDeniedController.add(denied);

    // ignore: avoid_print
    print('[LocationService] startTracking carId=$carId permission=$permission');

    if (denied) return;

    await _publishLocation();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _publishLocation());
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _carId = null;
  }

  Future<void> _publishLocation() async {
    if (_carId == null) return;
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } on LocationServiceDisabledException {
        // GPS hardware disabled — fall back to network/Wi-Fi location
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      }

      // ignore: avoid_print
      print('[LocationService] pos lat=${pos.latitude} lng=${pos.longitude} acc=${pos.accuracy}');

      Sentry.addBreadcrumb(Breadcrumb(
        message: 'GPS fix: lat=${pos.latitude.toStringAsFixed(5)} lng=${pos.longitude.toStringAsFixed(5)} acc=${pos.accuracy.toStringAsFixed(1)}m car=$_carId',
        category: 'gps',
        level: SentryLevel.info,
      ));

      if (pos.accuracy > 200) {
        // ignore: avoid_print
        print('[LocationService] accuracy too low (${pos.accuracy}m), skipping');
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'GPS accuracy too low: ${pos.accuracy}m — skipped upsert',
          category: 'gps',
          level: SentryLevel.warning,
        ));
        return;
      }
      await Supabase.instance.client.rpc('upsert_car_location', params: {
        'p_car_id': _carId,
        'p_latitude': pos.latitude,
        'p_longitude': pos.longitude,
        'p_accuracy': pos.accuracy,
        'p_recorded_at': DateTime.now().toUtc().toIso8601String(),
      });
      // ignore: avoid_print
      print('[LocationService] upsert ok');
    } on LocationServiceDisabledException catch (e, s) {
      // Both high and medium accuracy failed — location truly disabled
      // ignore: avoid_print
      print('[LocationService] location service disabled');
      _permissionDenied = true;
      _permissionDeniedController.add(true);
      await Sentry.captureException(e, stackTrace: s, withScope: (scope) {
        scope.setTag('component', 'location_service');
        scope.setTag('car_id', _carId ?? 'null');
      });
    } catch (e, s) {
      // ignore: avoid_print
      print('[LocationService] _publishLocation error: $e');
      await Sentry.captureException(e, stackTrace: s, withScope: (scope) {
        scope.setTag('component', 'location_service');
        scope.setTag('car_id', _carId ?? 'null');
        scope.setContexts('gps_error', {'car_id': _carId, 'error': e.toString()});
      });
    }
  }

  void dispose() {
    _timer?.cancel();
    _permissionDeniedController.close();
  }
}
