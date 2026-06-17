import '../../../../core/services/location_service.dart';

class StopLocationTracking {
  final LocationService _service;
  StopLocationTracking(this._service);

  void call() => _service.stopTracking();
}
