import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';

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

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPosts() async {
    try {
      final data = await apiService.getPosts();

      if (!mounted) return;

      setState(() {
        posts = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void openDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostScreen(
          postId: post.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchPosts,
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
            'Featured',
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
          else if (posts.isNotEmpty)
            _featuredArticle(posts.first)
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
              'Explore',
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
            if (post.image != null)
              Image.network(
                '${ApiService.baseUrl}${post.image}',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
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
            if (post.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${ApiService.baseUrl}${post.image}',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
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