import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_ui.dart';
import 'category_articles_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with AutomaticKeepAliveClientMixin {
  final ApiService apiService = ApiService();

  List<dynamic> categories = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // =========================
  // GET CATEGORIES
  // =========================
  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await apiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = List<dynamic>.from(data);
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

  // =========================
  // OPEN CATEGORY
  // =========================
  void openCategory(Map<String, dynamic> category) {
    final id = category['id'] as int;
    final name = category['name'].toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryArticlesPage(categoryId: id, categoryName: name),
      ),
    );
  }

  // =========================
  // GET ICON CATEGORY
  // =========================
  IconData getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'pemrograman':
        return Icons.code_rounded;

      case 'teknologi':
        return Icons.memory_rounded;

      case 'mobile':
        return Icons.smartphone_rounded;

      default:
        return Icons.category_outlined;
    }
  }

  // =========================
  // GET DESCRIPTION CATEGORY
  // =========================
  String getCategoryDescription(String name) {
    switch (name.toLowerCase()) {
      case 'pemrograman':
        return 'Coding, development, dan teknologi software.';

      case 'teknologi':
        return 'Informasi seputar perkembangan teknologi.';

      case 'mobile':
        return 'Dunia aplikasi dan teknologi mobile.';

      default:
        return 'Artikel berdasarkan topik pilihan.';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(onRefresh: fetchData, child: _buildContent());
  }

  // =========================
  // CONTENT
  // =========================
  Widget _buildContent() {
    if (isLoading) {
      return _buildLoading();
    }

    if (errorMessage != null) {
      return _buildError();
    }

    if (categories.isEmpty) {
      return _buildEmpty();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        // =========================
        // HEADER
        // =========================
        Text('Articles', style: AppType.pageTitle),

        const SizedBox(height: 6),

        Text(
          'Temukan artikel berdasarkan topik yang kamu minati.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 28),

        // =========================
        // CATEGORY LIST
        // =========================
        ...categories.map((category) => _buildCategoryCard(category)),
      ],
    );
  }

  // =========================
  // CATEGORY CARD
  // =========================
  Widget _buildCategoryCard(dynamic category) {
    final map = Map<String, dynamic>.from(category as Map);
    final name = map['name'].toString();
    final icon = getCategoryIcon(name);
    final description = getCategoryDescription(name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openCategory(map),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // =========================
                // ICON
                // =========================
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 24),
                ),

                const SizedBox(width: 16),

                // =========================
                // TEXT
                // =========================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // =========================
                // ARROW
                // =========================
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // LOADING
  // =========================
  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Container(
          width: 140,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
          ),
        ),

        const SizedBox(height: 10),

        Container(
          width: 260,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
          ),
        ),

        const SizedBox(height: 28),

        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // ERROR
  // =========================
  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ErrorStateView(
            message: errorMessage ?? 'Terjadi kesalahan.',
            onRetry: fetchData,
          ),
        ),
      ],
    );
  }

  // =========================
  // EMPTY
  // =========================
  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  color: AppColors.textMuted,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada kategori',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Kategori artikel belum tersedia.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
