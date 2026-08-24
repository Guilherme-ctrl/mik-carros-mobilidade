import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/mission.dart';
import '../../domain/repositories/missions_repository.dart';
import '../../domain/usecases/close_request.dart';
import '../../domain/usecases/get_missions_history.dart';
import '../../domain/usecases/get_my_missions.dart';
import '../../domain/usecases/report_outcome.dart';
import '../../domain/usecases/update_car_status.dart';
import '../../domain/usecases/watch_active_mission.dart';
import 'missions_state.dart';

class MissionsCubit extends Cubit<MissionsState> {
  final MissionsRepository _repository;
  final GetMyMissions _getMyMissions;
  final GetMissionsHistory _getMissionsHistory;
  final UpdateCarStatus _updateCarStatus;
  final WatchActiveMission _watchActiveMission;
  final ReportOutcome _reportOutcome;
  final CloseRequest _closeRequest;

  String? _carId;
  StreamSubscription<dynamic>? _realtimeSub;

  MissionsCubit(
    this._repository,
    this._getMyMissions,
    this._getMissionsHistory,
    this._updateCarStatus,
    this._watchActiveMission,
    this._reportOutcome,
    this._closeRequest,
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
    // Every row getMissionsForCar returns is this car's CURRENT assignment
    // (removed_at IS NULL AND is_current) — exactly one, per the "one current
    // mission per car" invariant this app still holds. A mission can have many
    // cars, and since the fila-missoes intent a car can have many OPEN rows,
    // but only one of them is current; the datasource filters on is_current
    // precisely so firstOrNull below cannot pick up a queued row.
    final activeResult = await _getMyMissions(carId);
    final historyResult = await _getMissionsHistory(carId);

    activeResult.fold(
      (f) => emit(MissionsError(f.message)),
      (missions) {
        final history = historyResult.fold(
          (_) => <Mission>[],
          (list) => list.where((m) => _isToday(m.createdAt)).toList(),
        );
        emit(MissionsLoaded(
          activeMission: missions.firstOrNull,
          history: history,
          carId: carId,
        ));
      },
    );
  }

  Future<void> updateStatus(String requestId, String newStatus) async {
    if (_carId == null) return;
    final result = await _updateCarStatus(requestId, _carId!, newStatus);
    result.fold(
      (f) => emit(MissionsError(f.message)),
      (_) => _loadMissions(_carId!),
    );
  }

  Future<void> reportOutcome(String requestId, String outcome) async {
    if (_carId == null) return;
    final result = await _reportOutcome(requestId, _carId!, outcome);
    result.fold(
      (f) => emit(MissionsError(f.message)),
      (_) => _loadMissions(_carId!),
    );
  }

  // Encerramento manual (20260824000002). Devolve true quando encerrou, para a
  // tela poder fechar o diálogo de confirmação só no sucesso e manter a
  // mensagem de erro visível quando o RPC recusa — tipicamente "ainda falta o
  // desfecho do carro X", que é acionável e não deve sumir sozinha.
  Future<bool> closeMission(String requestId) async {
    final result = await _closeRequest(requestId);
    return result.fold(
      (f) {
        emit(MissionsError(f.message));
        return false;
      },
      (_) {
        if (_carId != null) _loadMissions(_carId!);
        return true;
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
