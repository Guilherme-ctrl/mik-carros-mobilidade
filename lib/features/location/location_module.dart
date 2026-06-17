import 'package:flutter_modular/flutter_modular.dart';
import '../../core/services/location_service.dart';
import 'domain/usecases/start_location_tracking.dart';
import 'domain/usecases/stop_location_tracking.dart';

class LocationModule extends Module {
  @override
  void binds(Injector i) {
    i.addSingleton<LocationService>(LocationService.new);
    i.addSingleton<StartLocationTracking>(StartLocationTracking.new);
    i.addSingleton<StopLocationTracking>(StopLocationTracking.new);
  }
}
