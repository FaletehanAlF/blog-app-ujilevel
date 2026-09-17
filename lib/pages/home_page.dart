import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

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
  String? errorMessage;
  String searchQuery = '';
  bool _showClear = false;

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

  Future<void> fetchPosts({String? keyword}) async {
    final query = (keyword ?? searchQuery).trim();
    final bool isExplicitSearch = keyword != null;

    if (mounted) {
      setState(() {
        searchQuery = query;
        // Saat pencarian eksplisit, kosongkan daftar agar loading,
        // error, dan empty state tampil jelas untuk keyword tersebut.
        // Saat refresh/detail-back (tanpa keyword), pertahankan daftar
        // agar layar tidak berkedip dan query tetap dipakai.
        if (posts.isEmpty || isExplicitSearch) {
          isLoading = true;
          if (isExplicitSearch) posts = [];
        }
        errorMessage = null;
      });
    }

    try {
      final data = await apiService.getPosts(
        search: query.isEmpty ? null : query,
      );

      if (!mounted) return;

      setState(() {
        posts = data;
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
    return RefreshIndicator(
      onRefresh: () => fetchPosts(),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Header
          const Text(
            'Selamat datang di Narata!',
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

          const Text(
            'Artikel Pilihan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
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

          // Artikel lainnya
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

            ...posts.skip(1).map(
              (post) => _articleItem(post),
            ),
          ],
        ],
      ),
    );
  }

  Widget _featuredArticle(Post post) {
    return GestureDetector(
      onTap: () => openDetail(post),
      child: Container(
        height: 280,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _articleItem(Post post) {
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
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 90,
                    height: 90,
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
                    width: 90,
                    height: 90,
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.category,
                    style: const TextStyle(
                      color: Colors.grey,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}