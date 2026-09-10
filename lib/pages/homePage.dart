import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/pages/detail_post_screen.dart';
import 'package:belajar_flutter/widgets/post_card.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

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
  List<dynamic> categories = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  int? selectedCategoryId;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // --- LOGIC SAMA: GET /posts ---
  Future<void> fetchPosts() async {
    if (posts.isEmpty && errorMessage == null) {
      setState(() => isLoading = true);
    }
    try {
      final data = await apiService.getPosts();

      if (!mounted) return;

      setState(() {
        posts = data;
        isLoading = false;
        errorMessage = null;
      });
      fetchCategories();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (posts.isEmpty) errorMessage = error.toString();
      });

      if (posts.isNotEmpty) {
        showAppSnack(context, error.toString(), isError: true);
      }
    }
  }

  // --- LOGIC SAMA: GET /categories (untuk filter lokal) ---
  Future<void> fetchCategories() async {
    try {
      final data = await apiService.getCategories();
      if (!mounted) return;
      setState(() => categories = data);
    } catch (_) {
      // Filter opsional — gagal tidak mengganggu daftar artikel.
    }
  }

  // --- LOGIC SAMA: konfirmasi + DELETE /posts/:id ---
  Future<void> confirmDelete(Post post) async {
    final result = await showDeleteDialog(context, title: post.title);
    if (result == true) {
      await deletePost(post.id);
    }
  }

  Future<void> deletePost(int id) async {
    try {
      await apiService.deletePost(id);

      if (!mounted) return;

      setState(() {
        posts.removeWhere((post) => post.id == id);
      });

      showAppSnack(context, 'Artikel berhasil dihapus');
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.toString(), isError: true);
    }
  }

  Future<void> openAddArticle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );

    fetchPosts();
  }

  void openDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostScreen(postId: post.id),
      ),
    ).then((_) => fetchPosts());
  }

  // Filter lokal (tidak mengubah API): cari + kategori.
  List<Post> get filteredPosts {
    return posts.where((p) {
      final q = searchQuery.trim().toLowerCase();
      final matchQuery = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.content.toLowerCase().contains(q);
      final matchCategory =
          selectedCategoryId == null || p.categoryId == selectedCategoryId;
      return matchQuery && matchCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded,
                size: 19, color: AppColors.accent),
            SizedBox(width: 8),
            Text('Journal'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: fetchPosts,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddArticle,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Tulis',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        backgroundColor: AppColors.surface2,
        color: AppColors.accent,
        onRefresh: fetchPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page title + deskripsi singkat ──
                  const Text('TERKINI', style: AppType.sectionLabel),
                  const SizedBox(height: 8),
                  const Text(
                    'Cerita yang\nlayak dibaca.',
                    style: AppType.pageTitle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoading
                        ? 'Memuat artikel…'
                        : posts.isEmpty
                            ? 'Ruang untuk ide-ide terbaik Anda.'
                            : '${posts.length} artikel · diperbarui dari server',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSearch(),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildCategoryFilter(),
                  ],
                  const SizedBox(height: 24),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: (v) => setState(() => searchQuery = v),
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      cursorColor: AppColors.accent,
      decoration: appInputDecoration(
        hint: 'Cari artikel…',
        suffixIcon: searchQuery.isEmpty
            ? const Icon(Icons.search_rounded, size: 20)
            : IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() => searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'Semua',
            selected: selectedCategoryId == null,
            onTap: () => setState(() => selectedCategoryId = null),
          ),
          const SizedBox(width: 8),
          ...categories.map((c) {
            final id = c['id'] as int;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _filterChip(
                label: c['name'].toString(),
                selected: selectedCategoryId == id,
                onTap: () => setState(() => selectedCategoryId =
                    selectedCategoryId == id ? null : id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.onAccent
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const LoadingSkeletonList();
    }
    if (errorMessage != null) {
      return ErrorStateView(
        message: errorMessage!,
        onRetry: () {
          setState(() {
            isLoading = true;
            errorMessage = null;
          });
          fetchPosts();
        },
      );
    }
    if (posts.isEmpty) {
      return EmptyStateView(
        title: 'Belum ada artikel',
        subtitle:
            'Buat artikel pertama Anda dan bagikan ide terbaik Anda.',
        actionLabel: 'Tulis artikel pertama',
        onAction: openAddArticle,
      );
    }
    final items = filteredPosts;
    if (items.isEmpty) {
      return const EmptyStateView(
        title: 'Tidak ditemukan',
        subtitle: 'Coba kata kunci lain atau ubah filter kategori.',
        icon: Icons.search_off_rounded,
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final post = items[index];
        return PostCard(
          post: post,
          onDelete: () => confirmDelete(post),
          onTap: () => openDetail(post),
        );
      },
    );
  }
}
