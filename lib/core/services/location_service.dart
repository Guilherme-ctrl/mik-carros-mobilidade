import 'dart:async';
import 'package:geolocator/geolocator.dart';
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
      final pos = await Geolocator.getCurrentPosition();
      // ignore: avoid_print
      print('[LocationService] pos lat=${pos.latitude} lng=${pos.longitude} acc=${pos.accuracy}');
      if (pos.accuracy > 200) {
        // ignore: avoid_print
        print('[LocationService] accuracy too low (${pos.accuracy}m), skipping');
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
    } catch (e) {
      // ignore: avoid_print
      print('[LocationService] _publishLocation error: $e');
    }
  }

  void dispose() {
    _timer?.cancel();
    _permissionDeniedController.close();
  }
}
