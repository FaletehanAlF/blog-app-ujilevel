import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class _LikeCount extends StatelessWidget {
  final int count;
  const _LikeCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite_border_rounded,
          color: count > 0 ? const Color(0xFFE5484D) : AppColors.textMuted,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: count > 0 ? const Color(0xFFE5484D) : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ViewCount extends StatelessWidget {
  final int count;
  const _ViewCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.visibility_outlined,
          color: AppColors.textMuted,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();

  final TextEditingController searchController =
      TextEditingController();

  List<Post> posts = [];
  bool isLoading = true;
  bool _isLoadingMore = false;
  String? errorMessage;
  String? loadMoreError;
  String searchQuery = '';
  PostSort _sort = PostSort.latest;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _showClear = false;

  static const int _pageSize = 10;

  bool get _hasMore => _currentPage < _totalPages;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchTextChanged);
    fetchPosts();
  }

  void _onSearchTextChanged() {
    final show = searchController.text.isNotEmpty;
    if (show != _showClear && mounted) {
      setState(() {
        _showClear = show;
      });
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchTextChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPosts({String? keyword, PostSort? sort}) async {
    final query = (keyword ?? searchQuery).trim();
    final newSort = sort ?? _sort;
    final bool isExplicitSearch = keyword != null;
    final bool isSortChanged = sort != null && sort != _sort;
    // Sort berubah atau pencarian baru: reset ke page 1 dan hapus
    // hasil lama, lalu ambil data sesuai sort yang aktif.
    final bool isReload = isExplicitSearch || isSortChanged;

    if (mounted) {
      setState(() {
        searchQuery = query;
        _sort = newSort;
        // Muat ulang dari page 1: pencarian baru, clear pencarian,
        // ganti sort, pull-to-refresh, dan kembali dari detail selalu
        // mulai dari awal.
        // Saat pencarian eksplisit atau ganti sort, kosongkan daftar
        // agar loading, error, dan empty state tampil jelas.
        // Saat refresh/detail-back (tanpa keyword/sort), pertahankan
        // daftar agar layar tidak berkedip dan query tetap dipakai.
        if (posts.isEmpty || isReload) {
          isLoading = true;
          if (isReload) posts = [];
        }
        errorMessage = null;
        loadMoreError = null;
        _isLoadingMore = false;
      });
    }

    try {
      final result = await apiService.getPostsPaginated(
        search: query.isEmpty ? null : query,
        sort: newSort,
        page: 1,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        posts = result.posts;
        _currentPage = result.page;
        _totalPages = result.totalPages;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Mengambil halaman berikutnya dan menggabungkannya dengan artikel
  /// yang sudah tampil. Artikel lama tidak dihapus; saat error, daftar
  /// tetap dipertahankan dan pengguna bisa mencoba lagi.
  Future<void> loadMore() async {
    if (_isLoadingMore || isLoading || !_hasMore) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        loadMoreError = null;
      });
    }

    try {
      final result = await apiService.getPostsPaginated(
        search: searchQuery.isEmpty ? null : searchQuery,
        sort: _sort,
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        loadMoreError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> openDetail(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostScreen(
          postId: post.id,
        ),
      ),
    );

    if (!mounted) return;
    // Refresh setelah kembali dari detail (edit/hapus dari halaman detail).
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery untuk membaca ukuran layar dan menyesuaikan padding
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 32.0;

    return RefreshIndicator(
      onRefresh: () => fetchPosts(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // LayoutBuilder untuk menentukan layout berdasarkan ruang parent
          // breakpoint 600: digunakan di dalam GridView Artikel Terbaru
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 18,
                ),
        children: [
          // Header
          const Text(
            'Selamat datang di RuangKata!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Temukan sesuatu untuk dibaca.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // Search bar
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              FocusScope.of(context).unfocus();
              fetchPosts(keyword: value);
            },
            onChanged: (value) {
              // Jika dikosongkan saat mengetik, kembali ke semua artikel.
              if (value.trim().isEmpty && searchQuery.isNotEmpty) {
                fetchPosts(keyword: '');
              }
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Cari artikel...',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.grey,
                size: 21,
              ),
              suffixIcon: _showClear
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        searchController.clear();
                        FocusScope.of(context).unfocus();
                        fetchPosts(keyword: '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1C1C1C),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              // Flexible agar judul tidak overflow ketika sort button di samping
              const Flexible(
                child: Text(
                  'Artikel Pilihan',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<PostSort>(
                tooltip: 'Urutkan artikel',
                color: const Color(0xFF1C1C1C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value != _sort) fetchPosts(sort: value);
                },
                itemBuilder: (context) => PostSort.values
                    .map(
                      (option) => PopupMenuItem<PostSort>(
                        value: option,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (option == _sort)
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.grey,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sort_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _sort.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          // Artikel utama
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (errorMessage != null && posts.isEmpty)
            ErrorStateView(
              message: errorMessage!,
              onRetry: () => fetchPosts(),
            )
          else if (posts.isNotEmpty)
            _featuredArticle(posts.first)
          else if (searchQuery.isNotEmpty)
            Text(
              'Tidak ada artikel ditemukan untuk "$searchQuery".',
              style: const TextStyle(
                color: Colors.grey,
              ),
            )
          else
            const Text(
              'Belum ada artikel.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

          const SizedBox(height: 28),

          // Artikel lainnya - Responsive dengan LayoutBuilder
          // Mobile (<600): 1 kolom, Desktop (>=600): 2 kolom Grid
          if (posts.length > 1) ...[
            const Text(
              'Artikel Terbaru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, c) {
                final isMobile = c.maxWidth < 600;
                final items = posts.skip(1).toList();
                if (isMobile) {
                  // Mobile: satu kolom, tetap nyaman, tidak overflow
                  return Column(
                    children: items.map((post) => _articleItem(post)).toList(),
                  );
                }
                // Desktop/Web: 2 kolom, gunakan ruang lebih baik
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    // Rasio agar card tidak terlalu tinggi di desktop
                    childAspectRatio: 2.8,
                  ),
                  itemBuilder: (context, index) => _articleItem(items[index]),
                );
              },
            ),
          ],

          // Pagination: Muat Lebih Banyak.
          // Hanya tampil jika masih ada halaman berikutnya.
          if (!isLoading && errorMessage == null && posts.isNotEmpty) ...[
            const SizedBox(height: 8),

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
                  Text(
                    loadMoreError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: loadMore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Muat Lebih Banyak'),
                ),
              ),
          ],
        ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _featuredArticle(Post post) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // MediaQuery: tinggi card proporsional dengan lebar layar
    final cardHeight = screenWidth < 600 ? 280.0 : 320.0;
    return GestureDetector(
      onTap: () => openDetail(post),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (post.image != null && post.image!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: '${ApiService.baseUrl}${post.image}',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF1C1C1C),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF1C1C1C),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
              ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.category,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _ViewCount(count: post.viewCount),
                      const SizedBox(width: 12),
                      _LikeCount(count: post.likeCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _articleItem(Post post) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive image size via MediaQuery: adapt to available width
        final screenWidth = MediaQuery.sizeOf(context).width;
        final imageSize = screenWidth < 600 ? 90.0 : 100.0;
        return GestureDetector(
          onTap: () => openDetail(post),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (post.image != null && post.image!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: '${ApiService.baseUrl}${post.image}',
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: imageSize,
                        height: imageSize,
                        color: const Color(0xFF1C1C1C),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: imageSize,
                        height: imageSize,
                        color: const Color(0xFF1C1C1C),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.grey,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 12),

                // Expanded untuk mengisi sisa ruang pada Row (mencegah overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Flexible agar category tidak memaksa layout melebar
                      Flexible(
                        child: Text(
                          post.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _ViewCount(count: post.viewCount),

                const SizedBox(width: 10),

                _LikeCount(count: post.likeCount),
              ],
            ),
          ),
        );
      },
    );
  }
}