import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:image_picker/image_picker.dart';

/// Desain SAMA dengan Add: header → image → title → category →
/// content → aksi. Beda: data terisi, gambar lama tampil, aksi update.
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

  late TextEditingController titleController;
  late TextEditingController contentController;

  List<dynamic> categories = [];
  int? selectedCategory;

  XFile? selectedImage;
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
      text: widget.product['title'] ?? '',
    );

    contentController = TextEditingController(
      text: widget.product['content'] ?? '',
    );

    selectedCategory = widget.product['category_id'];

    existingImage = widget.product['image'];

    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

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

  // --- LOGIC SAMA: pilih gambar baru (opsional) ---
  Future<void> pickImage() async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      setState(() {
        selectedImage = image;
      });
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, 'Gagal memilih gambar: $error',
          isError: true);
    }
  }

  void cancelNewImage() => setState(() => selectedImage = null);

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

  // --- LOGIC SAMA: PUT /posts/:id ---
  // selectedImage null → gambar lama dipertahankan.
  // selectedImage ada  → gambar baru menggantikan yang lama.
  Future<void> updatePost() async {
    if (!validate()) return;

    final title = titleController.text.trim();
    final content = contentController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      await apiService.updatePost(
        widget.product['id'],
        title,
        content,
        selectedCategory!,
        selectedImage,
      );

      if (!mounted) return;

      Navigator.pop(context);
      showAppSnack(context, 'Artikel berhasil diperbarui');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showAppSnack(context, error.toString(), isError: true);
    }
  }

  String getImageUrl() {
    if (existingImage == null || existingImage!.isEmpty) {
      return '';
    }

    return '${ApiService.baseUrl}$existingImage';
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
        title: const Text('Edit Artikel'),
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
                const Text('Sempurnakan\ntulisan Anda.',
                    style: AppType.pageTitle),
                const SizedBox(height: 12),
                const Text(
                  'Perubahan langsung terlihat di daftar artikel.',
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                const FieldLabel('Gambar sampul', optional: true),
                _buildImageField(),
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
                    hint: 'Masukkan judul artikel',
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
                    hint: 'Edit isi artikel…',
                    hasError: contentError != null,
                  ),
                ),
                FieldError(message: contentError),
                const SizedBox(height: 24),
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

  Widget _buildImageField() {
    final url = getImageUrl();
    final hasExisting = url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: selectedImage != null
                ? FutureBuilder(
                    future: selectedImage!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                              ConnectionState.done &&
                          snapshot.hasData) {
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
                  )
                : hasExisting
                    ? Image.network(
                        url,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return _imagePlaceholder(
                              'Gambar lama tidak dapat dimuat');
                        },
                      )
                    : _imagePlaceholder(
                        'Belum ada gambar sampul'),
          ),
        ),
        if (selectedImage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gambar baru dipilih dan akan menggantikan gambar lama.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : pickImage,
                  icon: const Icon(Icons.image_outlined, size: 17),
                  label: Text(hasExisting || selectedImage != null
                      ? 'Ganti gambar'
                      : 'Pilih gambar'),
                ),
              ),
            ),
            if (selectedImage != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed:
                        isLoading ? null : cancelNewImage,
                    child:
                        const Text('Batalkan gambar baru'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _imagePlaceholder(String text) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined,
              color: AppColors.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ],
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
}
