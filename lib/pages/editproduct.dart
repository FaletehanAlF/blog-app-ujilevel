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
  final formKey = GlobalKey<FormState>();

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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
        ),
      );
    }
  }

  Future<void> updatePost() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori harus dipilih'),
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
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Edit Artikel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Artikel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Perbarui informasi artikel yang dipilih.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul Artikel',
                        hintText: 'Masukkan judul artikel',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul artikel harus diisi';
                        }

                        if (value.trim().length < 3) {
                          return 'Judul minimal 3 karakter';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contentController,
                      maxLines: 7,
                      decoration: InputDecoration(
                        labelText: 'Konten Artikel',
                        hintText: 'Masukkan isi artikel',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 100),
                          child: Icon(Icons.article_outlined),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Konten artikel harus diisi';
                        }

                        if (value.trim().length < 10) {
                          return 'Konten minimal 10 karakter';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    isLoadingCategories
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: const Icon(
                                Icons.category_outlined,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: categories.map<DropdownMenuItem<int>>(
                              (category) {
                                return DropdownMenuItem<int>(
                                  value: category['id'],
                                  child: Text(category['name']),
                                );
                              },
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategoryId = value;
                              });
                            },
                          ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : updatePost,
                        icon: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}