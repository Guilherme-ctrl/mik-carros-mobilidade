import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String? requestId;
  final String type;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    this.requestId,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id:        map['id'] as String,
        requestId: map['request_id'] as String?,
        type:      map['type'] as String,
        title:     map['title'] as String,
        body:      map['body'] as String,
        readAt:    map['read_at'] != null
            ? DateTime.parse(map['read_at'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, readAt];
}
