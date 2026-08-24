import 'package:equatable/equatable.dart';

// Uma mensagem do canal privado entre o gestor de carros e ESTE carro
// (car_messages, 20260824000005). Não confundir com Comment, que é o chat da
// missão e é visível a mais gente.
class CarMessage extends Equatable {
  final String id;
  final String authorId;
  final String authorName;
  // Gravado no envio, não derivado na leitura: a bolha precisa saber de que
  // lado veio sem consultar papel de ninguém, e uma mensagem antiga continua
  // dizendo quem a pessoa era quando escreveu.
  final String authorRole;
  final String content;
  final DateTime createdAt;

  const CarMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.createdAt,
  });

  bool get fromManager => authorRole == 'central_admin';

  factory CarMessage.fromMap(Map<String, dynamic> map) => CarMessage(
    id: map['id'] as String,
    authorId: map['author_id'] as String,
    authorName: (map['author_name'] as String?) ?? 'Usuário',
    authorRole: (map['author_role'] as String?) ?? '',
    content: map['content'] as String,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  @override
  List<Object?> get props => [
    id,
    authorId,
    authorName,
    authorRole,
    content,
    createdAt,
  ];
}
