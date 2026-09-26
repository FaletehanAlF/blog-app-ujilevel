import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/api.dart';
import '../widgets/app_ui.dart';
import '../widgets/profile_avatar.dart';
import 'editproduct.dart';
import 'public_profile_page.dart';

class DetailPostScreen extends StatefulWidget {
  final int postId;

  const DetailPostScreen({super.key, required this.postId});

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

  /// null = status like belum dimuat.
  bool? _isLiked;
  bool _isLikeWorking = false;
  int _likeCount = 0;
  int _viewCount = 0;

  /// True setelah view dicatat sekali. Mencegah POST berulang akibat
  /// rebuild maupun pemuatan ulang detail dari halaman edit.
  bool _viewRecorded = false;

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
        _likeCount = fetchedPost.likeCount;
        _viewCount = fetchedPost.viewCount;
      });

      _recordView();
      _loadBookmarkStatus();
      _loadLikeStatus();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  /// Mencatat satu view setelah detail berhasil dimuat.
  /// Hanya sekali per pembukaan halaman (bukan per rebuild).
  /// Gagal mencatat bukan error fatal: artikel tetap tampil dengan
  /// count sebelumnya dan tidak ada error view di halaman.
  Future<void> _recordView() async {
    if (_viewRecorded) return;
    _viewRecorded = true;

    try {
      final latest = await apiService.addPostView(widget.postId);

      if (!mounted) return;

      setState(() {
        _viewCount = latest;
      });
    } catch (_) {
      // Abaikan: halaman detail tetap bisa digunakan.
    }
  }

  /// Status bookmark dari backend (GET /bookmarks/:postId).
  /// Gagal memuat bukan error fatal: tombol memakai ikon default dan
  /// aksi toggle akan menampilkan error sebenarnya jika ada.
  Future<void> _loadBookmarkStatus() async {
    try {
      final bookmarked = await apiService.getBookmarkStatus(widget.postId);

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

  Future<void> _loadLikeStatus() async {
    try {
      final liked = await apiService.getLikeStatus(widget.postId);

      if (!mounted) return;

      setState(() {
        _isLiked = liked;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLiked = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (post == null || _isLikeWorking) return;

    // Status belum diketahui, muat dulu sebelum beraksi.
    if (_isLiked == null) {
      await _loadLikeStatus();
      if (!mounted || _isLiked == null) return;
    }

    setState(() {
      _isLikeWorking = true;
    });

    final wasLiked = _isLiked ?? false;

    try {
      if (wasLiked) {
        await apiService.removeLike(post!.id);
      } else {
        await apiService.addLike(post!.id);
      }

      if (!mounted) return;

      setState(() {
        _isLiked = !wasLiked;
        _isLikeWorking = false;
        _likeCount = wasLiked
            ? (_likeCount > 0 ? _likeCount - 1 : 0)
            : _likeCount + 1;
      });

      showAppSnack(context, wasLiked ? 'Like dihapus' : 'Like ditambahkan');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLikeWorking = false;
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

    final ok = await showDeleteDialog(context, title: post!.title);

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

      showAppSnack(context, error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ala referensi: tanpa AppBar, hero gambar penuh + kartu sheet.
    return Scaffold(
      backgroundColor: AppColors.background,
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
          child: CircularProgressIndicator(strokeWidth: 2.5),
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

    // Konten dibatasi agar nyaman di tablet/desktop (anti melebar).
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildHero(), _buildSheet()],
          ),
        ),
      ),
    );
  }

  /// Hero gambar ala referensi: tinggi proporsional terbatas,
  /// tombol kembali + bookmark melayang, gradien bawah menyatu ke sheet.
  Widget _buildHero() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Tinggi terbatas (clamp) agar tidak overflow di layar pendek/lebar.
    final heroHeight = (screenHeight * 0.42).clamp(280.0, 480.0);
    final imageUrl = (post!.image != null && post!.image!.isNotEmpty)
        ? '${ApiService.baseUrl}${post!.image}'
        : '';

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.surface2,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surface2,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textMuted,
                  size: 34,
                ),
              ),
            )
          else
            Container(
              color: AppColors.surface2,
              alignment: Alignment.center,
              child: Icon(
                Icons.article_outlined,
                color: AppColors.textMuted,
                size: 40,
              ),
            ),

          // Gradien atas (tombol terbaca) dan bawah (menyatu ke sheet)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.3, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Tombol melayang
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _heroCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                _buildHeroBookmark(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        color: iconColor ?? Colors.white,
        tooltip: tooltip,
      ),
    );
  }

  /// Tombol bookmark melayang ala referensi (emas saat tersimpan).
  Widget _buildHeroBookmark() {
    if (_isBookmarkWorking || _isBookmarked == null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.all(12),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final bookmarked = _isBookmarked ?? false;
    return _heroCircleButton(
      icon: bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      iconColor: bookmarked ? AppColors.gold : Colors.white,
      tooltip: bookmarked ? 'Hapus bookmark' : 'Simpan bookmark',
      onPressed: _toggleBookmark,
    );
  }

  /// Kartu sheet ala referensi yang menumpuk hero.
  Widget _buildSheet() {
    return Container(
      margin: const EdgeInsets.only(top: -28),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryLabel(
            label: post!.category.isEmpty ? 'Artikel' : post!.category,
          ),

          const SizedBox(height: 12),

          Text(post!.title, style: AppType.detailTitle),

          const SizedBox(height: 14),

          _buildAuthorRow(),

          const SizedBox(height: 12),

          // Meta: views + like (logika like tidak berubah)
          Row(
            children: [
              Flexible(child: _buildViewRow()),
              const SizedBox(width: 16),
              Flexible(child: _buildLikeButton()),
            ],
          ),

          const SizedBox(height: 18),

          Container(height: 1, color: AppColors.border),

          const SizedBox(height: 18),

          Text(post!.content, style: AppType.body),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
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
    );
  }

  Widget _buildLikeButton() {
    if (_isLikeWorking || _isLiked == null) {
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

    final liked = _isLiked ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _toggleLike,
          icon: Icon(
            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 22,
          ),
          color: liked ? const Color(0xFFE5484D) : null,
          tooltip: liked ? 'Hapus like' : 'Suka artikel',
        ),
        Text(
          _likeCount.toString(),
          style: TextStyle(
            color: liked ? const Color(0xFFE5484D) : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorRow() {
    final name = post?.authorName;
    final authorId = post?.author?.id ?? post?.userId;
    final canOpenProfile = authorId != null && authorId > 0;

    return GestureDetector(
      onTap: canOpenProfile ? () => _openAuthorProfile(authorId) : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          ProfileAvatar(imagePath: post?.authorProfileImage, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oleh',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
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
          if (canOpenProfile)
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
        ],
      ),
    );
  }

  void _openAuthorProfile(int authorId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicProfilePage(userId: authorId)),
    );
  }

  /// Jumlah view artikel dari backend. Diperbarui ke angka terbaru
  /// setelah POST view berhasil; sebelumnya memakai angka dari GET.
  Widget _buildViewRow() {
    return Row(
      children: [
        Icon(Icons.visibility_outlined, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 6),
        Text(
          '$_viewCount dilihat',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDeleting ? null : openEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Artikel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(isDeleting ? 'Menghapus...' : 'Hapus Artikel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
