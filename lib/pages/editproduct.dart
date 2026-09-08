import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProductPage extends StatefulWidget {
  final Map product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late final titleController = TextEditingController(text: widget.product['title']);
  late final priceController = TextEditingController(text: widget.product['price'].toString());
  late final descriptionController = TextEditingController(text: widget.product['description']);
  late final categoryController = TextEditingController(text: widget.product['category']);

  bool isSaving = false;

 Future<void> updateProduct() async {
    setState(() => isSaving = true);

    final response = await http.put(
      Uri.parse('https://fakestoreapi.com/products/${widget.product['id']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': titleController.text,
        'price': double.tryParse(priceController.text) ?? 0,
        'description': descriptionController.text,
        'category': categoryController.text,
      }),
    );

    setState(() => isSaving = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil memperbarui produk: ${response.statusCode}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui produk: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Produk'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga'),
            ),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : updateProduct,
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Perbarui'),
            ),
          ],
        ),
      ),
    );
  }
}