class Author {
  final int id;
  final String? name;
  final String? email;

  const Author({
    required this.id,
    this.name,
    this.email,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class Post {
  final int id;
  final String title;
  final String content;
  final int categoryId;
  final String category;
  final String? image;
  final int? userId;
  final Author? author;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.categoryId,
    required this.category,
    this.image,
    this.userId,
    this.author,
  });

  /// Nama pembuat artikel dari relasi posts.user_id -> users.id.
  /// Tidak ada hardcode: seluruhnya berasal dari response API.
  String? get authorName => author?.name;

  String? get authorEmail => author?.email;

  factory Post.fromJson(Map<String, dynamic> json) {
    Author? author;
    final authorJson = json['author'];

    if (authorJson is Map) {
      author = Author.fromJson(
        Map<String, dynamic>.from(authorJson),
      );
    } else if (json['user_id'] != null &&
        (json['author_name'] != null || json['author_email'] != null)) {
      // Fallback format flat dari API.
      author = Author(
        id: _toInt(json['user_id']) ?? 0,
        name: json['author_name']?.toString(),
        email: json['author_email']?.toString(),
      );
    }

    return Post(
      id: _toInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      categoryId: _toInt(json['category_id']) ?? 0,
      category: json['category']?.toString() ?? '',
      image: json['image']?.toString(),
      userId: _toInt(json['user_id']),
      author: author,
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
