import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/car_message.dart';

abstract class CarChatRepository {
  Future<Either<Failure, List<CarMessage>>> getMessages(String carId);
  Future<Either<Failure, void>> sendMessage(String carId, String content);
  Stream<Either<Failure, List<CarMessage>>> watchMessages(String carId);
}
