import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({
    super.key,
    required this.product,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final ApiService apiService = ApiService();
  final ImagePicker imagePicker = ImagePicker();

  late final TextEditingController titleController;
  late final TextEditingController contentController;

  List<dynamic> categories = [];
  XFile? selectedImage;

  int? selectedCategory;
  String? existingImage;

  bool isLoading = false;
  bool isLoadingCategories = true;

  String? categoryLoadError;
  String? titleError;
  String? contentError;
  String? categoryError;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.product['title']?.toString() ?? '',
    );

    contentController = TextEditingController(
      text: widget.product['content']?.toString() ?? '',
    );

    selectedCategory = _toInt(widget.product['category_id']);
    existingImage = widget.product['image']?.toString();

    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> fetchCategories() async {
    setState(() {
      isLoadingCategories = true;
      categoryLoadError = null;
    });

    try {
      final data = await apiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = data;
        isLoadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingCategories = false;
        categoryLoadError = error.toString();
      });
    }
  }

  Future<void> pickImage() async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null || !mounted) return;

      setState(() {
        selectedImage = image;
      });
    } catch (error) {
      if (!mounted) return;

      showAppSnack(
        context,
        'Gagal memilih gambar: $error',
        isError: true,
      );
    }
  }

  bool validate() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    setState(() {
      titleError = title.isEmpty
          ? 'Judul artikel wajib diisi'
          : title.length < 3
          ? 'Judul minimal 3 karakter'
          : null;

      contentError = content.isEmpty
          ? 'Konten artikel wajib diisi'
          : content.length < 10
          ? 'Konten minimal 10 karakter'
          : null;

      categoryError = selectedCategory == null
          ? 'Silakan pilih kategori'
          : null;
    });

    return titleError == null &&
        contentError == null &&
        categoryError == null;
  }

  Future<void> updatePost() async {
    if (!validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await apiService.updatePost(
        widget.product['id'],
        titleController.text.trim(),
        contentController.text.trim(),
        selectedCategory!,
        selectedImage,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showAppSnack(
        context,
        error.toString(),
        isError: true,
      );
    }
  }

  String get imageUrl {
    if (existingImage == null || existingImage!.isEmpty) {
      return '';
    }

    return '${ApiService.baseUrl}$existingImage';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: isLoading
              ? null
              : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Edit Artikel'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit artikel',
                  style: AppType.pageTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Perbarui informasi artikel yang sudah tersimpan.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                const FieldLabel(
                  'Gambar sampul',
                  optional: true,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedImage != null
                      ? 'Gambar baru akan menggantikan gambar sebelumnya.'
                      : 'Gambar lama tetap digunakan jika tidak diganti.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppRadius.lg,
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: selectedImage != null
                        ? FutureBuilder(
                            future: selectedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              }

                              return Container(
                                color: AppColors.surface2,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : hasImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                color: AppColors.surface,
                                child: Center(
                                  child: Text(
                                    'Gambar tidak dapat dimuat',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.surface,
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: AppColors.textMuted,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada gambar',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : pickImage,
                        icon: const Icon(
                          Icons.image_outlined,
                          size: 18,
                        ),
                        label: Text(
                          hasImage || selectedImage != null
                              ? 'Ganti Gambar'
                              : 'Pilih Gambar',
                        ),
                      ),
                    ),
                    if (selectedImage != null) ...[
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  selectedImage = null;
                                });
                              },
                        child: const Text('Batal'),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                const FieldLabel('Judul'),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Masukkan judul artikel',
                    hasError: titleError != null,
                  ),
                ),
                FieldError(message: titleError),

                const SizedBox(height: 20),

                const FieldLabel('Kategori'),
                const SizedBox(height: 8),

                if (isLoadingCategories)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppRadius.md,
                      ),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Memuat kategori...',
                          style: AppType.hint,
                        ),
                      ],
                    ),
                  )
                else if (categoryLoadError != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppRadius.md,
                      ),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Kategori tidak dapat dimuat.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: fetchCategories,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppRadius.md,
                      ),
                      border: Border.all(
                        color: categoryError != null
                            ? AppColors.danger
                            : AppColors.border,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: categories.any(
                          (category) =>
                              _toInt(category['id']) ==
                              selectedCategory,
                        )
                            ? selectedCategory
                            : null,
                        isExpanded: true,
                        dropdownColor: AppColors.surface2,
                        hint: Text(
                          'Pilih kategori',
                          style: AppType.hint,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        items: categories
                            .map<DropdownMenuItem<int>>(
                          (category) {
                            return DropdownMenuItem<int>(
                              value: _toInt(category['id']),
                              child: Text(
                                category['name'].toString(),
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  selectedCategory = value;
                                  categoryError = null;
                                });
                              },
                      ),
                    ),
                  ),

                FieldError(message: categoryError),

                const SizedBox(height: 20),

                const FieldLabel('Konten'),
                const SizedBox(height: 8),
                TextField(
                  controller: contentController,
                  minLines: 6,
                  maxLines: 10,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.7,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Edit isi artikel...',
                    hasError: contentError != null,
                  ),
                ),
                FieldError(message: contentError),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(
                      AppRadius.md,
                    ),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pastikan data sudah benar sebelum menyimpan perubahan.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                primaryButton(
                  label: 'Simpan Perubahan',
                  loading: isLoading,
                  onPressed: updatePost,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}