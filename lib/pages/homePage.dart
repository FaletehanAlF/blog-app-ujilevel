import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';
import 'package:belajar_flutter/widgets/post_card.dart';
import 'addproduct.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  final TextEditingController searchController = TextEditingController();

  List<Post> posts = [];
  List<Post> filteredPosts = [];

  bool isLoading = true;

  Future<void> fetchPosts() async {
    try {
      final data = await apiService.getPosts();

      if (!mounted) return;

      setState(() {
        posts = data;
        filteredPosts = data;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  void searchPosts(String query) {
    final keyword = query.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        filteredPosts = posts;
      } else {
        filteredPosts = posts.where((post) {
          return post.title.toLowerCase().contains(keyword) ||
              post.content.toLowerCase().contains(keyword) ||
              post.category.toLowerCase().contains(keyword);
        }).toList();
      }
    });
  }

  Future<void> confirmDelete(Post post) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Artikel?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Artikel "${post.title}" akan dihapus secara permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      deletePost(post.id);
    }
  }

  Future<void> deletePost(int id) async {
    try {
      await apiService.deletePost(id);

      if (!mounted) return;

      setState(() {
        posts.removeWhere((post) => post.id == id);
        filteredPosts.removeWhere((post) => post.id == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil dihapus'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  Future<void> openAddArticle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    );

    fetchPosts();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddArticle,
        elevation: 3,
        icon: const Icon(Icons.add),
        label: const Text(
          'Artikel',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchPosts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BLOG',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Your Stories.',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: Color(0xFF171717),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.auto_stories_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create, manage and explore your articles.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: searchController,
                        onChanged: searchPosts,
                        decoration: InputDecoration(
                          hintText: 'Search articles...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 21,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    searchPosts('');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'LATEST ARTICLES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: Color(0xFF777777),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAEAE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredPosts.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filteredPosts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = filteredPosts[index];

                        return PostCard(
                          post: post,
                          onDelete: () {
                            confirmDelete(post);
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPostScreen(
                                  postId: post.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredPosts.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = searchController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.auto_stories_outlined,
              size: 30,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isSearching ? 'No articles found' : 'No articles yet',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isSearching
                ? 'Try searching with another keyword.'
                : 'Start by creating your first article.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}