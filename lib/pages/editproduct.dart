import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api_service.dart';
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

  late TextEditingController titleController;
  late TextEditingController contentController;

  List<dynamic> categories = [];
  int? selectedCategory;

  XFile? selectedImage;
  String? existingImage;

  bool isLoading = false;
  bool isLoadingCategories = true;

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

  Future<void> fetchCategories() async {
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
      });

      _showMessage('Gagal mengambil kategori: $error');
    }
  }

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
      _showMessage('Gagal memilih gambar: $error');
    }
  }

  Future<void> updatePost() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty) {
      _showMessage('Judul artikel wajib diisi');
      return;
    }

    if (title.length < 3) {
      _showMessage('Judul minimal 3 karakter');
      return;
    }

    if (content.isEmpty) {
      _showMessage('Konten artikel wajib diisi');
      return;
    }

    if (content.length < 10) {
      _showMessage('Konten minimal 10 karakter');
      return;
    }

    if (selectedCategory == null) {
      _showMessage('Silakan pilih kategori');
      return;
    }

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil diperbarui'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close_rounded,
            size: 22,
          ),
        ),
        title: const Text(
          'Edit Article',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 36),

            _buildImageField(),

            const SizedBox(height: 26),

            _buildTitleField(),

            const SizedBox(height: 22),

            _buildCategoryField(),

            const SizedBox(height: 22),

            _buildContentField(),

            const SizedBox(height: 34),

            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPDATE',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Refine your\narticle.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'IMAGE',
          style: TextStyle(
            color: Color(0xFF777777),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: 9),

        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: selectedImage != null
              ? FutureBuilder(
                  future: selectedImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      );
                    }

                    return _buildImagePlaceholder();
                  },
                )
              : existingImage != null && existingImage!.isNotEmpty
                  ? Image.network(
                      getImageUrl(),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : _buildImagePlaceholder(),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : pickImage,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: Color(0xFF333333),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.image_outlined,
              size: 18,
            ),
            label: Text(
              selectedImage != null
                  ? 'CHANGE IMAGE'
                  : 'CHANGE IMAGE',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        if (selectedImage != null) ...[
          const SizedBox(height: 8),
          const Text(
            'New image selected. It will replace the current image.',
            style: TextStyle(
              color: Color(0xFF777777),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      color: const Color(0xFF171717),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFF555555),
        size: 40,
      ),
    );
  }

  Widget _buildTitleField() {
    return _buildFieldContainer(
      label: 'TITLE',
      child: TextField(
        controller: titleController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: Colors.white,
        textInputAction: TextInputAction.next,
        decoration: _inputDecoration(
          hint: 'Enter article title',
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return _buildFieldContainer(
      label: 'CATEGORY',
      child: isLoadingCategories
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedCategory,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1A),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF888888),
                ),
                hint: const Text(
                  'Select category',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: categories.map<DropdownMenuItem<int>>((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
            ),
    );
  }

  Widget _buildContentField() {
    return _buildFieldContainer(
      label: 'CONTENT',
      child: TextField(
        controller: contentController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.6,
        ),
        cursorColor: Colors.white,
        maxLines: 9,
        decoration: _inputDecoration(
          hint: 'Edit your article...',
        ),
      ),
    );
  }

  Widget _buildFieldContainer({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF292929),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF555555),
        fontSize: 14,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : updatePost,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: const Color(0xFF333333),
          disabledForegroundColor: const Color(0xFF777777),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'UPDATE ARTICLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  SizedBox(width: 9),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                ],
              ),
      ),
    );
  }
}