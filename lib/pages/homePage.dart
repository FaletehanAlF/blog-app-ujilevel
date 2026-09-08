import 'package:belajar_flutter/pages/editproduct.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'addproduct.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List product = [];

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    if (response.statusCode == 200) {
      print('Response body: ${response.body}');
      setState(() {
        product = json.decode(response.body);
      });
    } else {
      print('Failed to load posts');
    }
  }

  Future<void> deleteProduct(int id) async {
  final response = await http.delete(
    Uri.parse('https://fakestoreapi.com/products/$id'),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Produk Berhasil Dihapus: ${response.statusCode}')),
    );

    setState(() {
      product.removeWhere((p) => p['id'] == id);
    });
  } else {
    print('Gagal menghapus produk: ${response.statusCode}');
  }
}

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: product.length,
        itemBuilder: (context, index) {
          final itemProduct = product[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProductPage(product: itemProduct),
                ),
              );
              // Handle item tap, e.g., navigate to edit page
            },
            child: ListTile(
              leading: Image.network(itemProduct["image"]),
              title: Text(itemProduct['title']),
              subtitle: Text(itemProduct['body']),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  deleteProduct(itemProduct['id']);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}