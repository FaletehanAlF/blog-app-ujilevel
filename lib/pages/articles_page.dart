import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_ui.dart';
import 'category_articles_page.dart';
import 'category_page.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage>
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

  Future<void> fetchData() async {
    if (!mounted) return;

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
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void openCategory(Map<String, dynamic> category) {
    final id = _toInt(category['id']);

    if (id == null) return;

    final name = category['name']?.toString() ?? 'Kategori';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryArticlesPage(
          categoryId: id,
          categoryName: name,
        ),
      ),
    );
  }

  void openManageCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CategoryPage(),
      ),
    ).then((_) {
      fetchData();
    });
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: fetchData,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoading();
    }

    if (errorMessage != null) {
      return _buildError();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        32,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Categories',
                style: AppType.pageTitle,
              ),
            ),
            IconButton(
              onPressed: openManageCategories,
              icon: const Icon(
                Icons.settings_outlined,
                size: 22,
              ),
              tooltip: 'Kelola Kategori',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Jelajahi artikel berdasarkan kategori.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        if (categories.isEmpty)
          _buildEmpty()
        else
          ...categories.map(_buildCategoryCard),
      ],
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final data = Map<String, dynamic>.from(
      category as Map,
    );

    final name = data['name']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openCategory(data),
          borderRadius: BorderRadius.circular(
            AppRadius.lg,
          ),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(
                AppRadius.lg,
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        32,
      ),
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
        const SizedBox(height: 24),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(
                  AppRadius.lg,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 50,
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
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
            'Kategori akan muncul di sini setelah ditambahkan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}