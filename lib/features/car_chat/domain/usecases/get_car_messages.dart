import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/car_message.dart';
import '../repositories/car_chat_repository.dart';

class GetCarMessages {
  final CarChatRepository _repository;
  GetCarMessages(this._repository);

  Future<Either<Failure, List<CarMessage>>> call(String carId) =>
      _repository.getMessages(carId);
}
