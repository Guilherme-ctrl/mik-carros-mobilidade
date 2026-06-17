import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String requestId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.requestId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
        id:         map['id'] as String,
        requestId:  map['request_id'] as String,
        authorId:   map['author_id'] as String,
        authorName: map['author_name'] as String,
        content:    map['content'] as String,
        createdAt:  DateTime.parse(map['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, content];
}
