/// Kategori milik user. Ownership (user_id) ditentukan backend dari JWT.
class Category {
  final int id;
  final String name;
  final int? userId;
  final String? ownerName;

  const Category({
    required this.id,
    required this.name,
    this.userId,
    this.ownerName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      userId: _toInt(json['user_id']),
      ownerName: json['owner_name']?.toString(),
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
