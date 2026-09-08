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
        Uri.parse('http://192.168.1.5:8000/posts/${widget.postId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          post = Post.fromJson(data['data']);
          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
          ),
        ),
        title: const Text(
          'Article',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          if (post != null)
            IconButton(
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
              tooltip: 'Edit artikel',
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : post == null
              ? _buildNotFound()
              : _buildArticle(),
    );
  }

  Widget _buildArticle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArticleNumber(),
          const SizedBox(height: 28),
          _buildCategory(),
          const SizedBox(height: 14),
          Text(
            post!.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 44,
            height: 2,
            color: Colors.white,
          ),
          const SizedBox(height: 26),
          Text(
            post!.content,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 16,
              height: 1.8,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 42),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildArticleNumber() {
    return Row(
      children: [
        Text(
          'ARTICLE',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 28,
          height: 1,
          color: const Color(0xFF444444),
        ),
        const SizedBox(width: 10),
        Text(
          post!.id.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFF303030),
        ),
      ),
      child: Text(
        post!.category.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFF292929),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            color: Color(0xFF666666),
            size: 17,
          ),
          const SizedBox(width: 9),
          Text(
            'BLOG APP',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF292929),
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.article_outlined,
                color: Color(0xFF666666),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Article not found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'The article you are looking for does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}