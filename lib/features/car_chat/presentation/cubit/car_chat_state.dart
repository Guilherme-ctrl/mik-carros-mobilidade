import 'package:equatable/equatable.dart';
import '../../domain/entities/car_message.dart';

sealed class CarChatState extends Equatable {
  const CarChatState();
  @override
  List<Object?> get props => [];
}

class CarChatLoading extends CarChatState {}

class CarChatLoaded extends CarChatState {
  final List<CarMessage> messages;
  const CarChatLoaded(this.messages);
  @override
  List<Object?> get props => [messages];
}

class CarChatError extends CarChatState {
  final String message;
  const CarChatError(this.message);
  @override
  List<Object?> get props => [message];
}
