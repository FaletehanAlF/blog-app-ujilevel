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

  // --- LOGIC SAMA: ambil daftar artikel dari API ---
  Future<void> fetchPosts() async {
    // Refresh tenang (tanpa skeleton penuh) saat pull-to-refresh.
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
      // Kategori untuk filter diambil dari endpoint yang sudah ada.
      fetchCategories(silent: true);
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

  Future<void> fetchCategories({bool silent = false}) async {
    try {
      final data = await apiService.getCategories();
      if (!mounted) return;
      setState(() => categories = data);
    } catch (_) {
      // Filter kategori opsional — kegagalan tidak mengganggu daftar artikel.
    }
  }

  // --- LOGIC SAMA: konfirmasi + hapus via API ---
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

  // --- Filter lokal (tidak mengubah API): cari + kategori ---
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
            Icon(Icons.article_rounded, size: 21),
            SizedBox(width: 8),
            Text('Blog'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: fetchPosts,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded, size: 21),
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Tulis',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: fetchPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSearch(),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildCategoryFilter(),
                  ],
                  const SizedBox(height: 20),
                  _buildBody(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = posts.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artikel Terbaru',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isLoading
              ? 'Memuat artikel…'
              : total == 0
                  ? 'Belum ada artikel'
                  : '$total artikel tersedia',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: (v) => setState(() => searchQuery = v),
      textInputAction: TextInputAction.search,
      decoration: appInputDecoration(
        hint: 'Cari judul atau isi artikel…',
        suffixIcon: searchQuery.isEmpty
            ? const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 20)
            : IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() => searchQuery = '');
                },
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(label: 'Semua', selected: selectedCategoryId == null,
              onTap: () => setState(() => selectedCategoryId = null)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
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
        subtitle: 'Buat artikel pertama Anda dan bagikan ide terbaik Anda.',
        actionLabel: 'Tulis artikel pertama',
        onAction: openAddArticle,
      );
    }
    final items = filteredPosts;
    if (items.isEmpty) {
      return EmptyStateView(
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
