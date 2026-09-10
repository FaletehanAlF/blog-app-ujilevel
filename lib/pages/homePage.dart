import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';
import 'package:belajar_flutter/widgets/post_card.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

import 'addproduct.dart';

/// Konten tab Beranda (tanpa Scaffold sendiri).
/// Scaffold + AppBar + BottomNav + FAB dimiliki oleh MainShell
/// agar tidak ada AppBar ganda dan state tab tetap terjaga.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final ApiService apiService = ApiService();

  List<Post> posts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  bool get wantKeepAlive => true;

  // --- LOGIC SAMA: GET /posts ---
  Future<void> fetchPosts() async {
    if (posts.isEmpty && errorMessage == null) {
      setState(() => isLoading = true);
    }
    try {
      final data = await apiService.getPosts();

      if (!mounted) return;

      setState(() {
        posts = data;
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

  /// Dipanggil Shell setelah kembali dari Tambah Artikel.
  Future<void> refresh() => fetchPosts();

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

  Future<void> openAddArticle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );

    fetchPosts();
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
    super.build(context);
    return RefreshIndicator(
      backgroundColor: AppColors.surface2,
      color: AppColors.accent,
      onRefresh: fetchPosts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header seksi (judul halaman ada di AppBar Shell) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ARTIKEL TERBARU', style: AppType.sectionLabel),
                    Text(
                      isLoading
                          ? 'Memuat…'
                          : posts.isEmpty
                          ? 'Kosong'
                          : '${posts.length} artikel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBody(),
              ],
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
      return EmptyStateView(
        title: 'Belum ada artikel',
        subtitle: 'Buat artikel pertama Anda dan bagikan ide terbaik Anda.',
        actionLabel: 'Tulis artikel pertama',
        onAction: openAddArticle,
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
