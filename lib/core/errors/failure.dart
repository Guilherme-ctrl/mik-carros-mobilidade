abstract class Failure {
  final String message;
  const Failure(this.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CarNotConfiguredFailure extends Failure {
  const CarNotConfiguredFailure()
      : super('Carro não configurado para este usuário. Contate a Mesa Central.');
}
