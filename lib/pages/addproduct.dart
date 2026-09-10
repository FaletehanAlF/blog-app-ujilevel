import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:image_picker/image_picker.dart';

/// Struktur: header → image picker → title → category → content → aksi.
/// Satu bahasa desain dengan halaman Edit.
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

  // Aturan validasi sama — hanya tampil inline.
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

  // --- LOGIC SAMA: pilih gambar galeri ---
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

  void removeImage() => setState(() => selectedImage = null);

  // --- LOGIC SAMA: GET /categories ---
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
      categoryError =
          selectedCategory == null ? 'Silakan pilih kategori' : null;
    });

    return titleError == null &&
        contentError == null &&
        categoryError == null;
  }

  // --- LOGIC SAMA: POST /posts (multipart, gambar opsional) ---
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

      showAppSnack(context, error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
        title: const Text('Artikel Baru'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
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
                const Text('Tulis sesuatu\nyang bermakna.',
                    style: AppType.pageTitle),
                const SizedBox(height: 12),
                const Text(
                  'Lengkapi gambar, judul, kategori, dan konten.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                const FieldLabel('Gambar sampul', optional: true),
                _buildImagePicker(),
                const SizedBox(height: 20),
                const FieldLabel('Judul'),
                TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Contoh: Panduan Memulai Blog',
                    hasError: titleError != null,
                  ),
                ),
                FieldError(message: titleError),
                const SizedBox(height: 20),
                const FieldLabel('Kategori'),
                _buildCategoryField(),
                FieldError(message: categoryError),
                const SizedBox(height: 20),
                const FieldLabel('Konten'),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  minLines: 6,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.7),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Tulis isi artikel di sini…',
                    hasError: contentError != null,
                  ),
                ),
                FieldError(message: contentError),
                const SizedBox(height: 24),
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
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16),
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Memuat kategori…', style: AppType.hint),
          ],
        ),
      );
    }
    if (categoryLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text('Gagal memuat kategori.',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary)),
            ),
            TextButton.icon(
              onPressed: fetchCategories,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: categoryError != null
                ? AppColors.danger
                : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedCategory,
          isExpanded: true,
          dropdownColor: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          hint: const Text('Pilih kategori', style: AppType.hint),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: categories.map<DropdownMenuItem<int>>((category) {
            return DropdownMenuItem<int>(
              value: category['id'],
              child: Text(category['name'].toString()),
            );
          }).toList(),
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
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: selectedImage == null
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.lg),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              Icons
                                  .add_photo_alternate_outlined,
                              color: AppColors.textMuted,
                              size: 30),
                          SizedBox(height: 12),
                          Text(
                            'Tambah gambar sampul',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ketuk untuk memilih dari galeri',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : FutureBuilder<Uint8List>(
                      future: selectedImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        }
                        return Container(
                          color: AppColors.surface2,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: pickImage,
                  icon: Icon(
                      selectedImage == null
                          ? Icons.image_outlined
                          : Icons.swap_horiz_rounded,
                      size: 17),
                  label: Text(selectedImage == null
                      ? 'Pilih gambar'
                      : 'Ganti gambar'),
                ),
              ),
            ),
            if (selectedImage != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton.icon(
                    onPressed: removeImage,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger),
                    icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 17),
                    label: const Text('Hapus'),
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
