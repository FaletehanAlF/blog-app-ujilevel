import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final ApiService apiService = ApiService();
  final ImagePicker picker = ImagePicker();

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  List<dynamic> categories = [];
  int? selectedCategory;

  XFile? selectedImage;

  bool isLoading = false;
  bool isLoadingCategories = true;
  String? categoryLoadError;

  String? titleError;
  String? contentError;
  String? categoryError;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      selectedImage = image;
    });
  }

  void removeImage() {
    setState(() {
      selectedImage = null;
    });
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

  Future<void> createPost() async {
    if (!validate()) return;

    final title = titleController.text.trim();
    final content = contentController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      await apiService.createPost(
        title,
        content,
        selectedCategory!,
        selectedImage,
      );

      if (!mounted) return;

      Navigator.pop(context);
      showAppSnack(context, 'Artikel berhasil ditambahkan');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 21,
          ),
        ),

        title: const Text(
          'Artikel Baru',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 640,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Text(
                  'Tulis artikel baru',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Bagikan tulisan dan informasi yang ingin kamu sampaikan.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // GAMBAR
                const FieldLabel(
                  'Gambar Sampul',
                  optional: true,
                ),

                const SizedBox(height: 8),

                _buildImagePicker(),

                const SizedBox(height: 24),

                // JUDUL
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
                    hint: 'Contoh: Panduan Memulai Blog',
                    hasError: titleError != null,
                  ),
                ),

                FieldError(
                  message: titleError,
                ),

                const SizedBox(height: 20),

                // KATEGORI
                const FieldLabel('Kategori'),

                const SizedBox(height: 8),

                _buildCategoryField(),

                FieldError(
                  message: categoryError,
                ),

                const SizedBox(height: 20),

                // KONTEN
                const FieldLabel('Konten'),

                const SizedBox(height: 8),

                TextField(
                  controller: contentController,
                  maxLines: 9,
                  minLines: 7,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.7,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Tulis isi artikel di sini...',
                    hasError: contentError != null,
                  ),
                ),

                FieldError(
                  message: contentError,
                ),

                const SizedBox(height: 28),

                // BUTTON
                primaryButton(
                  label: 'Terbitkan Artikel',
                  loading: isLoading,
                  onPressed: createPost,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    if (isLoadingCategories) {
      return Container(
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
      );
    }

    if (categoryLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(15),
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
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'Gagal memuat kategori.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            TextButton(
              onPressed: fetchCategories,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return Container(
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
          color: categoryError != null
              ? AppColors.danger
              : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedCategory,
          isExpanded: true,
          dropdownColor: AppColors.surface2,
          borderRadius: BorderRadius.circular(
            AppRadius.md,
          ),

          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),

          hint: Text(
            'Pilih kategori',
            style: AppType.hint,
          ),

          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),

          items: categories
              .map<DropdownMenuItem<int>>(
                (category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(
                      category['name'].toString(),
                    ),
                  );
                },
              )
              .toList(),

          onChanged: (value) {
            setState(() {
              selectedCategory = value;
              categoryError = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: pickImage,
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppRadius.lg,
              ),
              child: selectedImage == null
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(
                          color: AppColors.border,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          AppRadius.lg,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .add_photo_alternate_outlined,
                            color:
                                AppColors.textMuted,
                            size: 28,
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Tambah gambar sampul',
                            style: TextStyle(
                              color:
                                  AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Pilih gambar dari galeri',
                            style: TextStyle(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FutureBuilder<Uint8List>(
                      future:
                          selectedImage!.readAsBytes(),
                      builder:
                          (context, snapshot) {
                        if (snapshot.hasData) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),

                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.black
                                        .withValues(
                                      alpha: 0.65,
                                    ),
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed:
                                        removeImage,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    color: Colors.white,
                                    tooltip:
                                        'Hapus gambar',
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Container(
                          color: AppColors.surface2,
                          alignment:
                              Alignment.center,
                          child:
                              const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: pickImage,
                  icon: Icon(
                    selectedImage == null
                        ? Icons.image_outlined
                        : Icons.swap_horiz_rounded,
                    size: 17,
                  ),
                  label: Text(
                    selectedImage == null
                        ? 'Pilih gambar'
                        : 'Ganti gambar',
                  ),
                ),
              ),
            ),

            if (selectedImage != null) ...[
              const SizedBox(width: 10),

              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: removeImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger
                          .withValues(alpha: 0.4),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}