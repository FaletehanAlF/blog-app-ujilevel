class Statistics {
  final int totalArticles;
  final int totalViews;
  final int totalLikes;
  final int totalBookmarks;

  const Statistics({
    required this.totalArticles,
    required this.totalViews,
    required this.totalLikes,
    required this.totalBookmarks,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalArticles: _toInt(json['total_articles']) ?? 0,
      totalViews: _toInt(json['total_views']) ?? 0,
      totalLikes: _toInt(json['total_likes']) ?? 0,
      totalBookmarks: _toInt(json['total_bookmarks']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_articles': totalArticles,
      'total_views': totalViews,
      'total_likes': totalLikes,
      'total_bookmarks': totalBookmarks,
    };
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}
