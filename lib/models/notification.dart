class NotificationModel {
  final int id;
  final String type;
  final String message;
  final int postId;
  final int actorUserId;
  final String actorName;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.postId,
    required this.actorUserId,
    required this.actorName,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _toInt(json['id']) ?? 0,
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      postId: _toInt(json['post_id'] ?? json['postId']) ?? 0,
      actorUserId:
          _toInt(json['actor_user_id'] ?? json['actorUserId']) ?? 0,
      actorName: json['actor_name']?.toString() ?? '',
      isRead: _toBool(json['is_read'] ?? json['isRead']),
      createdAt:
          _toDateTime(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value.toString().trim().toLowerCase();

  return normalized == 'true' || normalized == '1';
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();

  try {
    return DateTime.parse(value.toString()).toLocal();
  } catch (_) {
    return null;
  }
}
