import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api.dart';
import 'detail_post_screen.dart';
import '../widgets/app_ui.dart';
import '../widgets/profile_avatar.dart';

/// Profil publik user lain. Data berasal dari `GET /profile/:userId`.
/// Hanya menampilkan data publik (foto, nama, jumlah dan daftar
/// artikel); tidak ada password/JWT/data sensitif.
class PublicProfilePage extends StatefulWidget {
  final int userId;

  const PublicProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final ApiService _api = ApiService();

  String _name = 'Pengguna RuangKata';
  String? _profileImage;
  int? _articleCount;
  List<Post> _articles = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.getPublicProfile(widget.userId);

      if (!mounted) return;

      final name = data['name']?.toString();
      final profileImage = data['profile_image']?.toString();
      int? articleCount = _toInt(data['article_count']);

      final rawArticles = data['articles'] ?? data['posts'];
      final List<Post> articles = [];

      if (rawArticles is List) {
        for (final item in rawArticles.whereType<Map>()) {
          try {
            articles.add(
              Post.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {
            // Lewati satu item rusak tanpa menggagalkan halaman.
          }
        }
      }

      setState(() {
        if (name != null && name.isNotEmpty) _name = name;
        _profileImage = (profileImage != null && profileImage.isNotEmpty)
            ? profileImage
            : null;
        _articles = articles;
        _articleCount = articleCount ?? articles.length;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openDetail(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPostScreen(postId: post.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          tooltip: 'Kembali',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      final hPad = MediaQuery.sizeOf(context).width < 600 ? 20.0 : 32.0;
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 30),
        children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ErrorStateView(
              message: _errorMessage ?? 'Terjadi kesalahan.',
              onRetry: _fetchProfile,
            ),
          ),
        ],
      );
    }

    final hPad = MediaQuery.sizeOf(context).width < 600 ? 20.0 : 32.0;
    return RefreshIndicator(
      backgroundColor: AppColors.surface2,
      color: Colors.blue,
      onRefresh: _fetchProfile,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 30),
        children: [
          Center(
            child: Column(
              children: [
                ProfileAvatar(
                  imagePath: _profileImage,
                  size: 88,
                ),
                const SizedBox(height: 16),
                Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_articleCount ?? _articles.length} artikel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'ARTIKEL',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
              if (_articles.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada artikel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return Column(children: _articles.map(_buildArticleItem).toList());
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _articles.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 3.5,
                      ),
                      itemBuilder: (context, i) => _buildArticleItem(_articles[i]),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleItem(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => _openDetail(post),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.article_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                post.category.isNotEmpty ? post.category : 'Tanpa kategori',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.favorite_border_rounded,
              color: post.likeCount > 0
                  ? const Color(0xFFE5484D)
                  : AppColors.textMuted,
              size: 12,
            ),
            const SizedBox(width: 2),
            Text(
              post.likeCount.toString(),
              style: TextStyle(
                color: post.likeCount > 0
                    ? const Color(0xFFE5484D)
                    : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
          size: 21,
        ),
      ),
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
