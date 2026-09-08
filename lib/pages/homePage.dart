import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageextends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List product = [];

  Future<void> getProduct() async {
    final response = await http.get(Uri.parse('https://fakestoreapi.com/products'));
    if (response.statusCode == 200) {
      print(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
      ),
      body: ListView.builder(
        itemCount: product.length,
        itemBuilder: (context, index) {
          final productItem = product[index];
          return ListTile(
            title: Text(productItem['name']),
            subtitle: Text(productItem['description']),
          );
        },
      ),
    );
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    if (response.statusCode == 200) {
      setState(() {
        product = json.decode(response.body);
      });
    } else {
      print('Failed to load posts');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  @override
  widget.build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: product.length,
        itemBuilder: (context, index) {
          final itemProduct = product[index];
         return ListTile(
            title: Text(itemProduct['title']),
            subtitle: Text(itemProduct['Price'].toString()),
          );
        },
      )
    );
  }