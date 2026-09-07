class Post {
  final int id;
  final String title;
  final String content;
  final int categoryId;
  final String category;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.categoryId,
    required this.category,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      categoryId: json['category_id'],
      category: json['category'],
    );
  }
}