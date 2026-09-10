import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';
import 'package:belajar_flutter/widgets/post_card.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

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

  Future<void> fetchPosts() async {
    try {
      final data = await apiService.getPosts();

      if (!mounted) return;

      setState(() {
        posts = data.where((p) => p.categoryId == widget.categoryId).toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (posts.isEmpty) errorMessage = error.toString();
      });

      if (posts.isNotEmpty) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  // --- LOGIC SAMA: konfirmasi + DELETE /posts/:id ---
  Future<void> confirmDelete(Post post) async {
    final result = await showDeleteDialog(context, title: post.title);
    if (result == true) {
      await deletePost(post.id);
    }
  }

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

  void openDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostScreen(postId: post.id),
      ),
    ).then((_) => fetchPosts());
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
        title: Text(widget.categoryName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        backgroundColor: AppColors.surface2,
        color: AppColors.accent,
        onRefresh: fetchPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading
                        ? 'Memuat artikel…'
                        : posts.isEmpty
                        ? 'Belum ada artikel'
                        : '${posts.length} artikel',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const LoadingSkeletonList();
    }
    if (errorMessage != null) {
      return ErrorStateView(
        message: errorMessage!,
        onRetry: () {
          setState(() {
            isLoading = true;
            errorMessage = null;
          });
          fetchPosts();
        },
      );
    }
    if (posts.isEmpty) {
      return const EmptyStateView(
        title: 'Belum ada artikel',
        subtitle: 'Belum ada artikel pada kategori ini. Coba kategori lain.',
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          post: post,
          onDelete: () => confirmDelete(post),
          onTap: () => openDetail(post),
        );
      },
    );
  }
}
