import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api.dart';
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
  final ApiService apiService = ApiService();

  Post? post;
  bool isLoading = true;
  bool isDeleting = false;
  String? errorMessage;

  /// null = status bookmark belum dimuat.
  bool? _isBookmarked;
  bool _isBookmarkWorking = false;

  int? _currentUserId;
  String? _currentRole;

  /// True jika user boleh edit/hapus: pemilik artikel atau admin.
  /// Backend tetap menjadi penegak utama (403), UI hanya menyembunyikan aksi.
  bool get _canManage {
    if (post == null) return false;
    if (_currentRole == 'admin') return true;
    if (_currentUserId == null || post!.userId == null) return false;
    return post!.userId == _currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _loadSession();
    fetchPost();
  }

  Future<void> _loadSession() async {
    try {
      await apiService.init();
      final userId = await apiService.getUserId();
      final role = await apiService.getRole();
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _currentRole = role;
      });
    } catch (_) {
      // Abaikan, backend tetap menolak aksi yang tidak diizinkan (403).
    }
  }

  Future<void> fetchPost() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _isBookmarked = null;
    });

    try {
      final fetchedPost = await apiService.getPostById(widget.postId);

      if (!mounted) return;

      setState(() {
        post = fetchedPost;
        isLoading = false;
      });

      _loadBookmarkStatus();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  /// Status bookmark dari backend (GET /bookmarks/:postId).
  /// Gagal memuat bukan error fatal: tombol memakai ikon default dan
  /// aksi toggle akan menampilkan error sebenarnya jika ada.
  Future<void> _loadBookmarkStatus() async {
    try {
      final bookmarked =
          await apiService.getBookmarkStatus(widget.postId);

      if (!mounted) return;

      setState(() {
        _isBookmarked = bookmarked;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isBookmarked = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (post == null || _isBookmarkWorking) return;

    // Status belum diketahui, muat dulu sebelum beraksi.
    if (_isBookmarked == null) {
      await _loadBookmarkStatus();
      if (!mounted || _isBookmarked == null) return;
    }

    setState(() {
      _isBookmarkWorking = true;
    });

    final wasBookmarked = _isBookmarked ?? false;

    try {
      if (wasBookmarked) {
        await apiService.removeBookmark(post!.id);
      } else {
        await apiService.addBookmark(post!.id);
      }

      if (!mounted) return;

      setState(() {
        _isBookmarked = !wasBookmarked;
        _isBookmarkWorking = false;
      });

      showAppSnack(
        context,
        wasBookmarked ? 'Bookmark dihapus' : 'Bookmark ditambahkan',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isBookmarkWorking = false;
      });

      showAppSnack(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> openEdit() async {
    if (post == null) return;

    if (!_canManage) {
      showAppSnack(
        context,
        'Anda tidak memiliki akses untuk mengedit artikel ini.',
        isError: true,
      );
      return;
    }

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

    if (!_canManage) {
      showAppSnack(
        context,
        'Anda tidak memiliki akses untuk menghapus artikel ini.',
        isError: true,
      );
      return;
    }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
        actions: [
          if (post != null && !isLoading && errorMessage == null)
            _buildBookmarkButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar:
          post != null && !isLoading && errorMessage == null && _canManage
              ? _buildActionBar()
              : null,
    );
  }

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
          height: 500,
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
              if (post!.image != null && post!.image!.isNotEmpty)
                _buildHeroImage(),

              CategoryLabel(
                label: post!.category,
              ),

              const SizedBox(height: 14),

              Text(
                post!.title,
                style: AppType.detailTitle,
              ),

              const SizedBox(height: 12),

              _buildAuthorRow(),

              const SizedBox(height: 20),

              Container(
                height: 1,
                color: AppColors.border,
              ),

              const SizedBox(height: 20),

              Text(
                post!.content,
                style: AppType.body,
              ),

              const SizedBox(height: 24),

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

  Widget _buildBookmarkButton() {
    if (_isBookmarkWorking || _isBookmarked == null) {
      return const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final bookmarked = _isBookmarked ?? false;

    return IconButton(
      onPressed: _toggleBookmark,
      icon: Icon(
        bookmarked
            ? Icons.bookmark_rounded
            : Icons.bookmark_border_rounded,
        size: 22,
      ),
      color: bookmarked ? Colors.blue : null,
      tooltip: bookmarked ? 'Hapus bookmark' : 'Simpan bookmark',
    );
  }

  Widget _buildAuthorRow() {
    final name = post?.authorName;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            color: AppColors.textSecondary,
            size: 19,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Oleh',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (name == null || name.isEmpty)
                    ? 'Penulis tidak diketahui'
                    : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
          child: CachedNetworkImage(
            imageUrl: '${ApiService.baseUrl}${post!.image}',
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.surface2,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
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
            ),
          ),
        ),
      ),
    );
  }

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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleting ? null : confirmDelete,
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