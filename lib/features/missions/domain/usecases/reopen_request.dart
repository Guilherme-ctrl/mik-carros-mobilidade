import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/reopen_result.dart';
import '../repositories/missions_repository.dart';

// Contrapartida de [CloseRequest]: agora que encerrar é um ato humano, ele pode
// ser um ato humano errado — desfecho trocado, confirmação cedo demais.
class ReopenRequest {
  final MissionsRepository _repository;
  ReopenRequest(this._repository);

  Future<Either<Failure, ReopenResult>> call(String requestId) =>
      _repository.reopenRequest(requestId);
}
