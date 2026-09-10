import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/post.dart';
import '../pages/detail_post_screen.dart';
import '../widgets/post_card.dart';
import '../widgets/app_ui.dart';

class CategoryArticlesPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryArticlesPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryArticlesPage> createState() => _CategoryArticlesPageState();
}

class _CategoryArticlesPageState extends State<CategoryArticlesPage> {
  final ApiService apiService = ApiService();

  List<Post> posts = [];

  bool isLoading = true;
  String? errorMessage;

  // =========================
  // GET ARTICLES BY CATEGORY
  // =========================
  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await apiService.getPosts();

      if (!mounted) return;

      setState(() {
        posts = data
            .where((post) => post.categoryId == widget.categoryId)
            .toList();

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  // =========================
  // DELETE CONFIRMATION
  // =========================
  Future<void> confirmDelete(Post post) async {
    if (!mounted) return;

    final result = await showDeleteDialog(context, title: post.title);

    if (result == true) {
      await deletePost(post.id);
    }
  }

  // =========================
  // DELETE ARTICLE
  // =========================
  Future<void> deletePost(int id) async {
    try {
      await apiService.deletePost(id);

      if (!mounted) return;

      setState(() {
        posts.removeWhere((post) => post.id == id);
      });

      showAppSnack(context, 'Artikel berhasil dihapus');
    } catch (error) {
      if (!mounted) return;

      showAppSnack(context, error.toString(), isError: true);
    }
  }

  // =========================
  // OPEN DETAIL
  // =========================
  Future<void> openDetail(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostScreen(postId: post.id),
      ),
    );

    // Refresh data setelah kembali
    fetchPosts();
  }

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // =========================
      // APP BAR
      // =========================
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

        title: Text(
          widget.categoryName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),

      // =========================
      // BODY
      // =========================
      body: RefreshIndicator(
        backgroundColor: AppColors.surface2,
        color: Colors.blue,
        onRefresh: fetchPosts,
        child: _buildBody(),
      ),
    );
  }

  // =========================
  // MAIN BODY
  // =========================
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
        // =========================
        // HEADER
        // =========================
        Text(widget.categoryName, style: AppType.pageTitle),

        const SizedBox(height: 6),

        Text(
          'Jelajahi artikel yang tersedia dalam kategori ini.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        // =========================
        // ARTICLE LIST
        // =========================
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PostCard(
              post: post,
              onDelete: () => confirmDelete(post),
              onTap: () => openDetail(post),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // LOADING
  // =========================
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

  // =========================
  // ERROR
  // =========================
  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ErrorStateView(
            message: errorMessage ?? 'Terjadi kesalahan.',
            onRetry: fetchPosts,
          ),
        ),
      ],
    );
  }

  // =========================
  // EMPTY
  // =========================
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
                      Icons.article_outlined,
                      color: AppColors.textMuted,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Belum ada artikel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Belum ada artikel pada kategori ${widget.categoryName}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: fetchPosts,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('Coba Lagi'),
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
