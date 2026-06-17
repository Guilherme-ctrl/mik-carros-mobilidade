import 'package:equatable/equatable.dart';

class UserSession extends Equatable {
  final String id;
  final String email;
  final String role;

  const UserSession({
    required this.id,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [id, email, role];
}
