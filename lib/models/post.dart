class Author {
  final int id;
  final String? name;
  final String? email;
  final String? profileImage;

  const Author({
    required this.id,
    this.name,
    this.email,
    this.profileImage,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      profileImage: (json['profile_image'] ?? json['profileImage'])
          ?.toString(),
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
  final int likeCount;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.categoryId,
    required this.category,
    this.image,
    this.userId,
    this.author,
    this.likeCount = 0,
  });

  /// Nama pembuat artikel dari relasi posts.user_id -> users.id.
  /// Tidak ada hardcode: seluruhnya berasal dari response API.
  String? get authorName => author?.name;

  String? get authorEmail => author?.email;

  String? get authorProfileImage => author?.profileImage;

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
        profileImage: (json['author_profile_image'] ??
                json['author_profileImage'])
            ?.toString(),
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
      likeCount: _toInt(json['like_count']) ?? 0,
    );
  }
}

/// Hasil daftar artikel beserta metadata pagination dari backend.
///
/// Format backend yang terverifikasi:
/// `{ "data": [...], "pagination": { "page": 1, "limit": 10,
/// "total": 9, "totalPages": 1 } }`
class PaginatedPosts {
  final List<Post> posts;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginatedPosts({
    required this.posts,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  /// True jika masih ada halaman berikutnya yang bisa dimuat.
  bool get hasMore => page < totalPages;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
