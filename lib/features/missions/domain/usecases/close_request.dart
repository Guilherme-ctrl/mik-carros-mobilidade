import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/missions_repository.dart';

// Encerramento manual da missão (20260824000002).
//
// Separado de [ReportOutcome] de propósito, e é a separação que dá sentido ao
// resto: reportar "Achei"/"Não achei" apenas registra o desfecho daquele carro
// e é reversível; encerrar é o passo final, protegido por confirmação na tela.
// Antes os dois eram a mesma ação, e um toque acidental fechava a missão.
class CloseRequest {
  final MissionsRepository _repository;
  CloseRequest(this._repository);

  Future<Either<Failure, void>> call(String requestId) =>
      _repository.closeRequest(requestId);
}
