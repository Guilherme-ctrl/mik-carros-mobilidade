import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart' hide State;
import '../../../../core/errors/failure.dart';
import '../../domain/entities/car_message.dart';
import '../../domain/usecases/get_car_messages.dart';
import '../../domain/usecases/send_car_message.dart';
import '../../domain/usecases/watch_car_messages.dart';
import 'car_chat_state.dart';

class CarChatCubit extends Cubit<CarChatState> {
  final GetCarMessages _getMessages;
  final SendCarMessage _sendMessage;
  final WatchCarMessages _watchMessages;

  StreamSubscription<Either<Failure, List<CarMessage>>>? _sub;
  String? _carId;

  CarChatCubit(this._getMessages, this._sendMessage, this._watchMessages)
      : super(CarChatLoading());

  Future<void> init(String carId) async {
    _carId = carId;
    emit(CarChatLoading());

    final result = await _getMessages(carId);
    result.fold(
      (f) => emit(CarChatError(f.message)),
      (list) => emit(CarChatLoaded(list)),
    );

    _sub?.cancel();
    _sub = _watchMessages(carId).listen((either) {
      either.fold(
        // Falha no meio da conversa não apaga o que já está na tela: uma queda
        // de rede transformaria a conversa inteira numa mensagem de erro.
        (_) {},
        (list) => emit(CarChatLoaded(list)),
      );
    });
  }

  // Devolve a mensagem de erro (ou null no sucesso) em vez de emitir
  // CarChatError: um envio que falha não pode substituir a conversa na tela
  // por uma tela de erro. A falha é do envio, não do canal.
  Future<String?> send(String content) async {
    final carId = _carId;
    if (carId == null || content.trim().isEmpty) return null;
    final result = await _sendMessage(carId, content.trim());
    return result.fold((f) => f.message, (_) => null);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
