import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/missions_repository.dart';

class AddComment {
  final MissionsRepository _repository;
  AddComment(this._repository);

  Future<Either<Failure, void>> call(String requestId, String content) =>
      _repository.addComment(requestId, content);
}
