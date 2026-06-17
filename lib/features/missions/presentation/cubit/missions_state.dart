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

  MissionsLoaded({this.activeMission, required this.history});

  @override
  List<Object?> get props => [activeMission, history];
}

class MissionsError extends MissionsState {
  final String message;
  MissionsError(this.message);

  @override
  List<Object?> get props => [message];
}

class CarNotConfigured extends MissionsState {}
