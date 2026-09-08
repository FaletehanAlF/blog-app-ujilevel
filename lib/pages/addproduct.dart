import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  final ApiService apiService = ApiService();
  final formKey = GlobalKey<FormState>();

  List categories = [];
  int? selectedCategoryId;

  bool isSaving = false;
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
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

  Future<void> addPost() async {
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
      await apiService.createPost(
        titleController.text.trim(),
        contentController.text.trim(),
        selectedCategoryId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil ditambahkan'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan artikel: $error'),
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
        title: const Text('Tambah Artikel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Artikel',
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
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Konten Artikel',
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
                onPressed: isSaving ? null : addPost,
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}