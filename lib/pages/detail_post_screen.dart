import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/app_ui.dart';
import 'editproduct.dart';

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

  // --- LOGIC SAMA: ambil detail dari API ---
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

  // --- LOGIC SAMA: hapus via API, lalu kembali ke daftar ---
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
        title: const Text('Detail Artikel'),
        actions: [
          if (post != null && !isLoading)
            IconButton(
              onPressed: openEdit,
              tooltip: 'Edit artikel',
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          const SizedBox(width: 4),
        ],
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
      return ErrorStateView(
        message: errorMessage ?? 'Artikel tidak ditemukan.',
        onRetry: fetchPost,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryBadge(label: post!.category),
              const SizedBox(height: 12),
              Text(
                post!.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              if (post!.image != null && post!.image!.isNotEmpty)
                _buildImage(),
              Text(
                post!.content,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 15,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 28),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
                color: const Color(0xFFF3F4F6),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        color: AppColors.textMuted, size: 32),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kelola artikel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Perbarui isi artikel atau hapus secara permanen.',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: openEdit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isDeleting ? null : confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: Color(0xFFF3C2C2)),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.danger),
                        )
                      : const Icon(Icons.delete_outline_rounded,
                          size: 17),
                  label: Text(isDeleting ? 'Menghapus…' : 'Hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
