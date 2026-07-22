import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/mission.dart';
import '../../domain/repositories/missions_repository.dart';
import '../../domain/usecases/get_my_missions.dart';
import '../../domain/usecases/set_outcome_found.dart';
import '../../domain/usecases/set_outcome_not_found.dart';
import '../../domain/usecases/update_mission_status.dart';
import '../../domain/usecases/watch_active_mission.dart';
import 'missions_state.dart';

class MissionsCubit extends Cubit<MissionsState> {
  final MissionsRepository _repository;
  final GetMyMissions _getMyMissions;
  final UpdateMissionStatus _updateMissionStatus;
  final WatchActiveMission _watchActiveMission;
  final SetOutcomeNotFound _setOutcomeNotFound;
  final SetOutcomeFound _setOutcomeFound;

  String? _carId;
  StreamSubscription<Mission?>? _realtimeSub;

  MissionsCubit(
    this._repository,
    this._getMyMissions,
    this._updateMissionStatus,
    this._watchActiveMission,
    this._setOutcomeNotFound,
    this._setOutcomeFound,
  ) : super(MissionsInitial());

  Future<void> init() async {
    emit(MissionsLoading());

    final carResult = await _repository.getDriverCarId();
    final carId = carResult.fold((_) => null, (id) => id);

    if (carId == null) {
      emit(CarNotConfigured());
      return;
    }

    _carId = carId;
    await _loadMissions(carId);

    // T10.15 — subscribe after initial load; each emission triggers a refresh
    _realtimeSub?.cancel();
    _realtimeSub = _watchActiveMission(carId).listen(
      (_) => _loadMissions(carId),
      onError: (_) {}, // realtime errors are non-fatal; next poll will recover
    );
  }

  Future<void> _loadMissions(String carId) async {
    final result = await _getMyMissions(carId);
    result.fold(
      (f) => emit(MissionsError(f.message)),
      (missions) {
        final active = missions.where((m) => m.status.isActive).firstOrNull;
        final history = missions
            .where((m) => m.status.isTerminal && _isToday(m.createdAt))
            .toList();
        emit(MissionsLoaded(activeMission: active, history: history));
      },
    );
  }

  Future<void> updateStatus(String requestId, String newStatus) async {
    final result = await _updateMissionStatus(requestId, newStatus);
    result.fold(
      (f) => emit(MissionsError(f.message)),
      (_) {
        if (_carId != null) _loadMissions(_carId!);
      },
    );
  }

  Future<void> setOutcomeNotFound(String requestId) async {
    final result = await _setOutcomeNotFound(requestId);
    result.fold(
      (f) => emit(MissionsError(f.message)),
      (_) {
        if (_carId != null) _loadMissions(_carId!);
      },
    );
  }

  Future<void> setOutcomeFound(String requestId) async {
    final result = await _setOutcomeFound(requestId);
    result.fold(
      (f) => emit(MissionsError(f.message)),
      (_) {
        if (_carId != null) _loadMissions(_carId!);
      },
    );
  }

  Future<void> retry() => init();

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
