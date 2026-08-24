import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/car_message.dart';
import '../repositories/car_chat_repository.dart';

class WatchCarMessages {
  final CarChatRepository _repository;
  WatchCarMessages(this._repository);

  Stream<Either<Failure, List<CarMessage>>> call(String carId) =>
      _repository.watchMessages(carId);
}
