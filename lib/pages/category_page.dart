import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/app_ui.dart';
import 'category_articles_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final ApiService apiService = ApiService();

  List<dynamic> categories = [];

  bool isLoading = true;
  String? errorMessage;

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

  Future<void> addCategory() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _CategoryFormDialog(
          title: 'Tambah Kategori',
          subtitle: 'Tambahkan kategori baru untuk artikel.',
          buttonText: 'Simpan',
          initialValue: '',
          onSave: apiService.createCategory,
        );
      },
    );

    if (result != true || !mounted) return;

    await fetchData();

    if (!mounted) return;

    showAppSnack(
      context,
      'Kategori berhasil ditambahkan',
    );
  }

  Future<void> editCategory(Map<String, dynamic> category) async {
    final id = _toInt(category['id']);

    if (id == null) {
      showAppSnack(
        context,
        'ID kategori tidak valid',
        isError: true,
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) {
        return _CategoryFormDialog(
          title: 'Edit Kategori',
          subtitle: 'Perbarui nama kategori yang dipilih.',
          buttonText: 'Simpan Perubahan',
          initialValue: category['name']?.toString() ?? '',
          onSave: (name) {
            return apiService.updateCategory(id, name);
          },
        );
      },
    );

    if (result != true || !mounted) return;

    await fetchData();

    if (!mounted) return;

    showAppSnack(
      context,
      'Kategori berhasil diubah',
    );
  }

  Future<void> deleteCategory(Map<String, dynamic> category) async {
    final id = _toInt(category['id']);
    final name = category['name']?.toString() ?? '';

    if (id == null) {
      showAppSnack(
        context,
        'ID kategori tidak valid',
        isError: true,
      );
      return;
    }

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

      showAppSnack(
        context,
        'Kategori berhasil dihapus',
      );
    } catch (error) {
      if (!mounted) return;

      showAppSnack(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
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

  int? _toInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kelola Kategori',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: _buildContent(),
      ),
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
        Text(
          'Categories',
          style: AppType.pageTitle,
        ),
        const SizedBox(height: 6),
        Text(
          'Kelola kategori artikel yang tersedia.',
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
            onPressed: addCategory,
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
                IconButton(
                  onPressed: () => editCategory(data),
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
  final String subtitle;
  final String buttonText;
  final String initialValue;
  final Future<void> Function(String name) onSave;

  const _CategoryFormDialog({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState
    extends State<_CategoryFormDialog> {
  late final TextEditingController controller;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> saveCategory() async {
    final name = controller.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Nama kategori tidak boleh kosong',
      );
      return;
    }

    if (name.length < 3) {
      _showMessage(
        'Nama kategori minimal 3 karakter',
      );
      return;
    }

    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      await widget.onSave(name);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showMessage(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 480,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            AppRadius.lg,
          ),
          border: Border.all(
            color: AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 12),
              color: Colors.black.withValues(
                alpha: 0.18,
              ),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.initialValue.isEmpty
                        ? Icons.add_rounded
                        : Icons.edit_outlined,
                    color: Colors.blue,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const FieldLabel(
              'Nama kategori',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              enabled: !isSaving,
              textCapitalization:
                  TextCapitalization.words,
              textInputAction:
                  TextInputAction.done,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.accent,
              decoration: appInputDecoration(
                hint: 'Contoh: Pendidikan',
              ),
              onSubmitted: (_) {
                if (!isSaving) {
                  saveCategory();
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              false,
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          AppRadius.md,
                        ),
                      ),
                      side: BorderSide(
                        color: AppColors.border,
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? () {}
                        : saveCategory,
                    style: ButtonStyle(
                      minimumSize:
                          WidgetStateProperty.all(
                        const Size.fromHeight(46),
                      ),
                      backgroundColor:
                          WidgetStateProperty.all(
                        Colors.blue,
                      ),
                      foregroundColor:
                          WidgetStateProperty.all(
                        Colors.white,
                      ),
                      overlayColor:
                          WidgetStateProperty.all(
                        Colors.blue.shade700,
                      ),
                      elevation:
                          WidgetStateProperty.all(0),
                      shape:
                          WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            AppRadius.md,
                          ),
                        ),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.buttonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}