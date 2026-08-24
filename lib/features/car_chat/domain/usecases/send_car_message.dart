import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/car_chat_repository.dart';

class SendCarMessage {
  final CarChatRepository _repository;
  SendCarMessage(this._repository);

  Future<Either<Failure, void>> call(String carId, String content) =>
      _repository.sendMessage(carId, content);
}
