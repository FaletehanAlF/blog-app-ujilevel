import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProductPage extends StatefulWidget {
  final Map product;

  const EditProductPage({
    super.key,
    required this.product,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;

  final ApiService apiService = ApiService();

  List categories = [];
  int? selectedCategoryId;

  bool isSaving = false;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.product['title'],
    );

    contentController = TextEditingController(
      text: widget.product['content'],
    );

    selectedCategoryId = widget.product['category_id'];

    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final data = await apiService.getCategories();

      setState(() {
        categories = data;
        isLoadingCategories = false;
      });
    } catch (error) {
      setState(() {
        isLoadingCategories = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  Future<void> updatePost() async {
    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data harus diisi'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await apiService.updatePost(
        widget.product['id'],
        titleController.text.trim(),
        contentController.text.trim(),
        selectedCategoryId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil diperbarui'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui artikel: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Artikel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Artikel',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Konten Artikel',
              ),
            ),
            const SizedBox(height: 16),
            isLoadingCategories
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                    ),
                    items: categories.map<DropdownMenuItem<int>>((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(category['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : updatePost,
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Perbarui'),
            ),
          ],
        ),
      ),
    );
  }
}