import 'package:equatable/equatable.dart';
import '../../domain/entities/mission.dart';

abstract class MissionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MissionsInitial extends MissionsState {}

class MissionsLoading extends MissionsState {}

class MissionsLoaded extends MissionsState {
  final Mission? activeMission;
  final List<Mission> history;
  // The DRIVER'S car, not the mission's. Needed by QueueBadge, which watches a
  // queue that belongs to the car — a Mission can be served by several cars
  // (multi-carro-missao), so this could not live on the entity. MissionsCubit
  // already resolves it; before this change it was private and unreachable from
  // the widget tree.
  final String carId;

  MissionsLoaded({
    this.activeMission,
    required this.history,
    required this.carId,
  });

  @override
  List<Object?> get props => [activeMission, history, carId];
}

class MissionsError extends MissionsState {
  final String message;
  MissionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class CarNotConfigured extends MissionsState {}
