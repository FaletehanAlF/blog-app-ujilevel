import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/post.dart';

class ApiService {
  static const String baseUrl = 'http:';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  // Posts

  Future<List<Post>> getPosts() async {
    final response = await _dio.get('/posts');

    if (response.statusCode == 200) {
      return (response.data['data'] as List)
          .map((e) => Post.fromJson(e))
          .toList();
    }

    throw Exception('Gagal mengambil data artikel');
  }

  Future<Post> getPostById(int id) async {
    final response = await _dio.get('/posts/$id');

    if (response.statusCode == 200) {
      return Post.fromJson(response.data['data']);
    }

    throw Exception('Gagal mengambil detail artikel');
  }

  Future<void> createPost(
    String title,
    String content,
    int categoryId,
    XFile? image,
  ) async {
    final formData = FormData.fromMap({
      'title': title,
      'content': content,
      'category_id': categoryId.toString(),
    });

    if (image != null) {
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        ),
      );
    }

    final response = await _dio.post(
      '/posts',
      data: formData,
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Gagal menambahkan artikel: ${response.data}',
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
    final formData = FormData.fromMap({
      'title': title,
      'content': content,
      'category_id': categoryId.toString(),
    });

    if (image != null) {
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        ),
      );
    }

    final response = await _dio.put(
      '/posts/$id',
      data: formData,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memperbarui artikel: ${response.data}',
      );
    }
  }

  Future<void> deletePost(int id) async {
    final response = await _dio.delete('/posts/$id');

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus artikel');
    }
  }

  // Categories

  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get('/categories');

    if (response.statusCode == 200) {
      return response.data['data'];
    }

    throw Exception('Gagal mengambil data kategori');
  }

  Future<void> createCategory(String name) async {
    final response = await _dio.post(
      '/categories',
      data: {
        'name': name,
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Gagal menambahkan kategori: ${response.data}',
      );
    }
  }

  Future<void> updateCategory(
    int id,
    String name,
  ) async {
    final response = await _dio.put(
      '/categories/$id',
      data: {
        'name': name,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memperbarui kategori: ${response.data}',
      );
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await _dio.delete(
      '/categories/$id',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghapus kategori: ${response.data}',
      );
    }
  }
}