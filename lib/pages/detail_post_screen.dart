import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api_service.dart';
import '../widgets/app_ui.dart';
import 'editproduct.dart';

class DetailPostScreen extends StatefulWidget {
  final int postId;

  const DetailPostScreen({super.key, required this.postId});

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  Post? post;
  bool isLoading = true;
  bool isDeleting = false;
  String? errorMessage;
  final ApiService apiService = ApiService();

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
        actions: [
          if (post != null && !isLoading)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              tooltip: 'Kelola artikel',
              color: AppColors.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: AppColors.border),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  openEdit();
                } else if (value == 'delete') {
                  confirmDelete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Hapus',
                        style: TextStyle(color: AppColors.danger, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textMuted,
                      size: 30,
                    ),
                    SizedBox(height: 8),
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
}
