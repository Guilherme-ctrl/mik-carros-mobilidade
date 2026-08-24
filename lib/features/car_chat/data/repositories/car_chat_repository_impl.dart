import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/car_message.dart';
import '../../domain/repositories/car_chat_repository.dart';
import '../datasources/car_chat_remote_datasource.dart';

class CarChatRepositoryImpl implements CarChatRepository {
  final CarChatRemoteDatasource _datasource;
  CarChatRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<CarMessage>>> getMessages(String carId) async {
    try {
      final rows = await _datasource.getMessages(carId);
      return Right(rows.map(CarMessage.fromMap).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage(String carId, String content) async {
    try {
      await _datasource.sendMessage(carId, content);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<CarMessage>>> watchMessages(String carId) {
    // Cada sinal do Realtime vira uma busca completa, embrulhada em Either —
    // nenhum Stream cru cruza a fronteira do repositório, e um erro de rede no
    // meio da conversa vira Left em vez de derrubar o StreamBuilder.
    return _datasource.watchMessages(carId).asyncMap((_) => getMessages(carId));
  }
}
