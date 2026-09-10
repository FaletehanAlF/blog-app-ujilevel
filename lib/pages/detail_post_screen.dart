import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/app_ui.dart';
import 'editproduct.dart';

/// Halaman baca: hero image → category → title → content → action.
/// Artikel TIDAK dibungkus card — fokus pada keterbacaan.
class DetailPostScreen extends StatefulWidget {
  final int postId;

  const DetailPostScreen({
    super.key,
    required this.postId,
  });

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  Post? post;
  bool isLoading = true;
  bool isDeleting = false;
  String? errorMessage;
  final ApiService apiService = ApiService();

  // --- LOGIC SAMA: GET /posts/:id ---
  Future<void> fetchPost() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetchedPost = await apiService.getPostById(widget.postId);

      if (!mounted) return;

      setState(() {
        post = fetchedPost;
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

  Future<void> openEdit() async {
    if (post == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(
          product: {
            'id': post!.id,
            'title': post!.title,
            'content': post!.content,
            'category_id': post!.categoryId,
            'category': post!.category,
            'image': post!.image,
          },
        ),
      ),
    );

    fetchPost();
  }

  // --- LOGIC SAMA: DELETE /posts/:id lalu kembali ---
  Future<void> confirmDelete() async {
    if (post == null || isDeleting) return;
    final ok = await showDeleteDialog(context, title: post!.title);
    if (!ok) return;

    setState(() => isDeleting = true);
    try {
      await apiService.deletePost(post!.id);
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, 'Artikel berhasil dihapus');
    } catch (error) {
      if (!mounted) return;
      setState(() => isDeleting = false);
      showAppSnack(context, error.toString(), isError: true);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPost();
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
        title: const Text('Artikel'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12),
            Text(
              'Memuat artikel…',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    if (errorMessage != null || post == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ErrorStateView(
            message: errorMessage ?? 'Artikel tidak ditemukan.',
            onRetry: fetchPost,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero image ──
              if (post!.image != null && post!.image!.isNotEmpty)
                _buildHeroImage(),
              // ── Category ──
              CategoryLabel(label: post!.category),
              const SizedBox(height: 12),
              // ── Title (fokus utama) ──
              Text(post!.title, style: AppType.detailTitle),
              const SizedBox(height: 20),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 20),
              // ── Content ──
              Text(post!.content, style: AppType.body),
              const SizedBox(height: 32),
              // ── Action: Edit primary, Delete subtle ──
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Image.network(
            '${ApiService.baseUrl}${post!.image}',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.surface2,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textMuted, size: 30),
                    SizedBox(height: 8),
                    Text('Gambar tidak dapat dimuat',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: openEdit,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isDeleting ? null : confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(
                        color: AppColors.dangerBorder),
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.danger),
                        )
                      : const Icon(Icons.delete_outline_rounded,
                          size: 17),
                  label:
                      Text(isDeleting ? 'Menghapus…' : 'Hapus'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
