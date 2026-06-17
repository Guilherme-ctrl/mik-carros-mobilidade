import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/comment.dart';
import '../repositories/missions_repository.dart';

class GetComments {
  final MissionsRepository _repository;
  GetComments(this._repository);

  Future<Either<Failure, List<Comment>>> call(String requestId) =>
      _repository.getComments(requestId);
}
