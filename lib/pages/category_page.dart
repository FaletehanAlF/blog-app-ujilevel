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

  Future<void> fetchData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

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

  Future<void> showAddCategoryDialog() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _CategoryFormDialog(
          title: 'Tambah Kategori',
          buttonText: 'Simpan',
          controller: controller,
          apiService: apiService,
          onSave: () async {
            await apiService.createCategory(
              controller.text.trim(),
            );
          },
          onSuccess: () async {
            if (!mounted) return;

            Navigator.pop(dialogContext);

            await fetchData();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kategori berhasil ditambahkan'),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> showEditCategoryDialog(
    Map<String, dynamic> category,
  ) async {
    final controller = TextEditingController(
      text: category['name'].toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _CategoryFormDialog(
          title: 'Edit Kategori',
          buttonText: 'Simpan Perubahan',
          controller: controller,
          apiService: apiService,
          onSave: () async {
            final id = category['id'] as int;

            await apiService.updateCategory(
              id,
              controller.text.trim(),
            );
          },
          onSuccess: () async {
            if (!mounted) return;

            Navigator.pop(dialogContext);

            await fetchData();

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kategori berhasil diubah'),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> deleteCategory(
    Map<String, dynamic> category,
  ) async {
    final id = category['id'] as int;
    final name = category['name'].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kategori'),
          content: Text(
            'Apakah kamu yakin ingin menghapus kategori "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await apiService.deleteCategory(id);

      if (!mounted) return;

      await fetchData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void openCategory(Map<String, dynamic> category) {
    final id = category['id'] as int;
    final name = category['name'].toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryArticlesPage(
          categoryId: id,
          categoryName: name,
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text(
          'Categories',
          style: AppType.pageTitle,
        ),
        const SizedBox(height: 6),
        Text(
          'Temukan artikel berdasarkan topik yang kamu minati.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: showAddCategoryDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Kategori'),
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
    final data = Map<String, dynamic>.from(category as Map);
    final name = data['name'].toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openCategory(data),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    getCategoryIcon(name),
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        getCategoryDescription(name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showEditCategoryDialog(data),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                  ),
                  tooltip: 'Edit kategori',
                ),
                IconButton(
                  onPressed: () => deleteCategory(data),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                  tooltip: 'Hapus kategori',
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
        const SizedBox(height: 20),
        Container(
          width: 160,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(vertical: 50),
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
            'Tambahkan kategori pertama untuk artikel.',
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

class _CategoryFormDialog extends StatefulWidget {
  final String title;
  final String buttonText;
  final TextEditingController controller;
  final ApiService apiService;
  final Future<void> Function() onSave;
  final Future<void> Function() onSuccess;

  const _CategoryFormDialog({
    required this.title,
    required this.buttonText,
    required this.controller,
    required this.apiService,
    required this.onSave,
    required this.onSuccess,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  bool isSaving = false;

  Future<void> saveCategory() async {
    final name = widget.controller.text.trim();

    if (name.isEmpty) {
      _showMessage('Nama kategori tidak boleh kosong');
      return;
    }

    if (name.length < 3) {
      _showMessage('Nama kategori minimal 3 karakter');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await widget.onSave();

      if (!mounted) return;

      await widget.onSuccess();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        enabled: !isSaving,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nama Kategori',
          hintText: 'Contoh: Teknologi',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) {
          if (!isSaving) {
            saveCategory();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: isSaving
              ? null
              : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : saveCategory,
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(widget.buttonText),
        ),
      ],
    );
  }
}