import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.9:8000';

  Future<List<Post>> getPosts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data['data'] as List)
          .map((e) => Post.fromJson(e))
          .toList();
    } else {
      throw Exception('Gagal mengambil data artikel');
    }
  }

  Future<Post> getPostById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts/$id'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return Post.fromJson(data['data']);
    } else {
      throw Exception('Gagal mengambil detail artikel');
    }
  }

  Future<void> deletePost(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus artikel');
    }
  }

  Future<void> createPost(
    String title,
    String content,
    int categoryId,
    XFile? image,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts'),
    );

    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['category_id'] = categoryId.toString();

    if (image != null) {
      final bytes = await image.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('STATUS CREATE: ${response.statusCode}');
    print('RESPONSE CREATE: $responseBody');

    if (response.statusCode != 201) {
      throw Exception(
        'Gagal menambahkan artikel: $responseBody',
      );
    }
  }

  Future<void> updatePost(
    int id,
    String title,
    String content,
    int categoryId,
    XFile? image,
  ) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/posts/$id'),
    );

    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['category_id'] = categoryId.toString();

    // Jika user memilih gambar baru,
    // gambar tersebut dikirim ke backend.
    if (image != null) {
      final bytes = await image.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name,
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('STATUS UPDATE: ${response.statusCode}');
    print('RESPONSE UPDATE: $responseBody');

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memperbarui artikel: $responseBody',
      );
    }
  }

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['data'];
    } else {
      throw Exception('Gagal mengambil data kategori');
    }
  }
}