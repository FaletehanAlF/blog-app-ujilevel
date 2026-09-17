import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api.dart';
import '../pages/detail_post_screen.dart';
import '../widgets/app_ui.dart';

/// Artikel yang disimpan user yang sedang login.
/// Backend menentukan kepemilikan dari JWT.
class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  final ApiService apiService = ApiService();

  static const int _pageSize = 10;

  List<Post> posts = [];

  bool isLoading = true;
  bool _isLoadingMore = false;
  String? errorMessage;
  String? loadMoreError;

  int _currentPage = 1;
  int _totalPages = 1;

  bool get _hasMore => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();
    fetchBookmarks();
  }

  Future<void> fetchBookmarks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      loadMoreError = null;
      _isLoadingMore = false;
    });

    try {
      final result = await apiService.getBookmarks(
        page: 1,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        posts = result.posts;
        _currentPage = result.page;
        _totalPages = result.totalPages;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Halaman berikutnya digabung dengan yang sudah tampil.
  /// Saat error, daftar tetap dipertahankan dan bisa dicoba lagi.
  Future<void> loadMore() async {
    if (_isLoadingMore || isLoading || !_hasMore) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        loadMoreError = null;
      });
    }

    try {
      final result = await apiService.getBookmarks(
        page: _currentPage + 1,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        final existingIds = posts.map((post) => post.id).toSet();
        posts = [
          ...posts,
          ...result.posts.where(
            (post) => !existingIds.contains(post.id),
          ),
        ];
        _currentPage = result.page;
        _totalPages = result.totalPages;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        loadMoreError =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> openDetail(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostScreen(postId: post.id),
      ),
    );

    if (!mounted) return;
    // Artikel bisa di-unbookmark dari detail, jadi muat ulang page 1.
    fetchBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          tooltip: 'Kembali',
        ),
        title: const Text(
          'Bookmark',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        backgroundColor: AppColors.surface2,
        color: Colors.blue,
        onRefresh: fetchBookmarks,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoading();
    }

    if (errorMessage != null) {
      return _buildError();
    }

    if (posts.isEmpty) {
      return _buildEmpty();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('Bookmark', style: AppType.pageTitle),
        const SizedBox(height: 6),
        Text(
          'Artikel yang kamu simpan.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ...posts.map(_buildBookmarkItem),
        if (_isLoadingMore)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (loadMoreError != null)
          Column(
            children: [
              const SizedBox(height: 8),
              Text(
                loadMoreError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: loadMore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          )
        else if (_hasMore)
          Center(
            child: OutlinedButton(
              onPressed: loadMore,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Muat Lebih Banyak'),
            ),
          ),
      ],
    );
  }

  Widget _buildBookmarkItem(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => openDetail(post),
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
            Icons.bookmark_border_rounded,
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
        subtitle: Text(
          post.category.isNotEmpty ? post.category : 'Tanpa kategori',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Container(
          width: 150,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 270,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 24),
        const LoadingSkeletonList(),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ErrorStateView(
            message: errorMessage ?? 'Terjadi kesalahan.',
            onRetry: fetchBookmarks,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.bookmark_border_rounded,
                      color: AppColors.textMuted,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada bookmark',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Artikel yang kamu simpan akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
