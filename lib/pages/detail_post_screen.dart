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

  // =========================
  // GET DETAIL ARTIKEL
  // =========================
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

  // =========================
  // EDIT ARTIKEL
  // =========================
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

    // Ambil ulang data setelah kembali dari halaman edit
    fetchPost();
  }

  // =========================
  // HAPUS ARTIKEL
  // =========================
  Future<void> confirmDelete() async {
    if (post == null || isDeleting) return;

    final ok = await showDeleteDialog(
      context,
      title: post!.title,
    );

    if (!ok) return;

    setState(() {
      isDeleting = true;
    });

    try {
      await apiService.deletePost(post!.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      showAppSnack(
        context,
        error.toString(),
        isError: true,
      );
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
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
          ),
          tooltip: 'Kembali',
        ),

        title: const Text(
          'Detail Artikel',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),

      body: _buildBody(),

      // =========================
      // ACTION BAR
      // =========================
      bottomNavigationBar:
          post != null && !isLoading && errorMessage == null
              ? _buildActionBar()
              : null,
    );
  }

  // =========================
  // BODY
  // =========================
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
          ),
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
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 680,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // HERO IMAGE
              // =========================
              if (post!.image != null && post!.image!.isNotEmpty)
                _buildHeroImage(),

              // =========================
              // CATEGORY
              // =========================
              CategoryLabel(
                label: post!.category,
              ),

              const SizedBox(height: 14),

              // =========================
              // TITLE
              // =========================
              Text(
                post!.title,
                style: AppType.detailTitle,
              ),

              const SizedBox(height: 20),

              // =========================
              // DIVIDER
              // =========================
              Container(
                height: 1,
                color: AppColors.border,
              ),

              const SizedBox(height: 20),

              // =========================
              // CONTENT
              // =========================
              Text(
                post!.content,
                style: AppType.body,
              ),

              const SizedBox(height: 24),

              // =========================
              // PETUNJUK
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(
                    AppRadius.md,
                  ),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gunakan tombol di bawah untuk mengedit atau menghapus artikel.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // HERO IMAGE
  // =========================
  Widget _buildHeroImage() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24,
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            AppRadius.lg,
          ),
          child: Image.network(
            '${ApiService.baseUrl}${post!.image}',
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                color: AppColors.surface2,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textMuted,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gambar tidak dapat dimuat',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================
  // ACTION BAR
  // =========================
  Widget _buildActionBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            // =========================
            // EDIT
            // =========================
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleting ? null : openEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                ),
                label: const Text(
                  'Edit Artikel',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(
                    color: AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppRadius.md,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // =========================
            // HAPUS
            // =========================
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleting
                    ? null
                    : confirmDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                      ),
                label: Text(
                  isDeleting
                      ? 'Menghapus...'
                      : 'Hapus Artikel',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppRadius.md,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}