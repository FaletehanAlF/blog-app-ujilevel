import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import 'editproduct.dart';

class DetailPostScreen extends StatefulWidget {
  final int postId;

  const DetailPostScreen({
    super.key,
    required this.postId,
  });

  @override
  State<DetailPostScreen> createState() => _DetailPostScreenState();
}

class _DetailPostScreenState extends State<DetailPostScreen> {
  Post? post;
  bool isLoading = true;

  Future<void> fetchPost() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/posts/${widget.postId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          post = Post.fromJson(data['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil artikel: $error'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPost();
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
          'Detail Artikel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (post != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit artikel',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductPage(
                      product: {
                        'id': post!.id,
                        'title': post!.title,
                        'content': post!.content,
                        'category_id': post!.categoryId,
                        'category': post!.category,
                      },
                    ),
                  ),
                );

                fetchPost();
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : post == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Artikel tidak ditemukan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post!.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              post!.category,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            post!.content,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.7,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}