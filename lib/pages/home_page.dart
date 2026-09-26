import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class _LikeCount extends StatelessWidget {
  final int count;

  /// True saat tampil di atas gambar (teks selalu terang).
  final bool light;

  const _LikeCount({required this.count, this.light = false});

  @override
  Widget build(BuildContext context) {
    final color = light
        ? Colors.white70
        : (count > 0 ? const Color(0xFFE5484D) : AppColors.textMuted);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite_border_rounded, color: color, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            count.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewCount extends StatelessWidget {
  final int count;

  /// True saat tampil di atas gambar (teks selalu terang).
  final bool light;

  const _ViewCount({required this.count, this.light = false});

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white70 : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility_outlined, color: color, size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            count.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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

  final TextEditingController searchController = TextEditingController();

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

  /// Toggle kolom pencarian ala referensi (ikon search di header).
  bool _showSearch = false;

  /// Index carousel unggulan untuk titik indikator.
  int _featuredIndex = 0;

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
          ...result.posts.where((post) => !existingIds.contains(post.id)),
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
        builder: (context) => DetailPostScreen(postId: post.id),
      ),
    );

    if (!mounted) return;
    // Refresh setelah kembali dari detail (edit/hapus dari halaman detail).
    fetchPosts();
  }

  /// Tab urutan ala referensi, dipetakan ke sort yang didukung backend.
  /// "Populer" tidak dibuat karena backend tidak menyediakan sort views/likes.
  List<({String label, PostSort sort})> get _tabs => const [
    (label: 'Rekomendasi', sort: PostSort.latest),
    (label: 'Terlama', sort: PostSort.oldest),
    (label: 'A-Z', sort: PostSort.titleAsc),
  ];

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
          // breakpoint 600: konten dibatasi agar nyaman di tablet/desktop
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 18,
                ),
                children: [
                  // Header ala referensi: judul besar + ikon pencarian
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Temukan',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() => _showSearch = !_showSearch);
                            if (!_showSearch) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          icon: Icon(
                            _showSearch
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 21,
                          ),
                          tooltip: 'Cari artikel',
                        ),
                      ),
                    ],
                  ),

                  // Search bar (expandable)
                  if (_showSearch) ...[
                    const SizedBox(height: 14),
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
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      cursorColor: AppColors.gold,
                      decoration: InputDecoration(
                        hintText: 'Cari artikel...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted,
                          size: 21,
                        ),
                        suffixIcon: _showClear
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textMuted,
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
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide(color: AppColors.gold),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Artikel utama: carousel ala referensi
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null && posts.isEmpty)
                    ErrorStateView(
                      message: errorMessage!,
                      onRetry: () => fetchPosts(),
                    )
                  else if (posts.isNotEmpty)
                    _featuredCarousel(posts.take(5).toList())
                  else if (searchQuery.isNotEmpty)
                    Text(
                      'Tidak ada artikel ditemukan untuk "$searchQuery".',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    Text(
                      'Belum ada artikel.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),

                  const SizedBox(height: 22),

                  // Tab urutan ala referensi (scroll horizontal anti-overflow)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tab in _tabs)
                          Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: _sortTab(
                              label: tab.label,
                              selected: _sort == tab.sort,
                              onTap: () {
                                if (tab.sort != _sort) {
                                  fetchPosts(sort: tab.sort);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Daftar artikel: baris thumbnail + teks ala referensi
                  if (!isLoading && errorMessage == null && posts.isNotEmpty)
                    Column(
                      children: posts.map((post) => _articleRow(post)).toList(),
                    ),

                  // Pagination: Muat Lebih Banyak.
                  // Hanya tampil jika masih ada halaman berikutnya.
                  if (!isLoading &&
                      errorMessage == null &&
                      posts.isNotEmpty) ...[
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

  /// Tab urutan dengan garis bawah emas untuk tab aktif (ala referensi).
  Widget _sortTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 3,
            width: 26,
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  /// Carousel unggulan ala referensi: gambar + gradien + judul overlay.
  /// AspectRatio menjaga tinggi proporsional di semua ukuran layar.
  Widget _featuredCarousel(List<Post> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: PageView.builder(
            itemCount: items.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _featuredIndex = index);
              }
            },
            itemBuilder: (context, index) => _featuredCard(items[index]),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < items.length; i++)
                Container(
                  width: _featuredIndex == i ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _featuredIndex == i
                        ? AppColors.gold
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _featuredCard(Post post) {
    final imageUrl = (post.image != null && post.image!.isNotEmpty)
        ? '${ApiService.baseUrl}${post.image}'
        : '';

    return GestureDetector(
      onTap: () => openDetail(post),
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
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
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    _imageFallback(iconSize: 30),
              )
            else
              _imageFallback(iconSize: 30),

            // Gradien agar judul terbaca di atas gambar
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      post.category.isEmpty ? 'Artikel' : post.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: _ViewCount(count: post.viewCount, light: true),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: _LikeCount(count: post.likeCount, light: true),
                      ),
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

  /// Baris artikel ala referensi: thumbnail kiri + judul + meta.
  /// Expanded/Flexible di semua teks agar tidak overflow di layar sempit.
  Widget _articleRow(Post post) {
    final imageUrl = (post.image != null && post.image!.isNotEmpty)
        ? '${ApiService.baseUrl}${post.image}'
        : '';

    return GestureDetector(
      onTap: () => openDetail(post),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surface2,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _imageFallback(iconSize: 22),
                      )
                    : _imageFallback(iconSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.category.isEmpty ? 'Artikel' : post.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(child: _ViewCount(count: post.viewCount)),
                      const SizedBox(width: 12),
                      Flexible(child: _LikeCount(count: post.likeCount)),
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

  Widget _imageFallback({required double iconSize}) {
    return Container(
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textMuted,
        size: iconSize,
      ),
    );
  }
}
