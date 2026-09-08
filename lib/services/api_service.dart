import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<List<dynamic>> getPosts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    } else {
      throw Exception('Gagal mengambil data artikel');
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
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/posts'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'title': title,
      'content': content,
      'category_id': categoryId,
    }),
  );

  if (response.statusCode != 201) {
    throw Exception('Gagal menambahkan artikel');
  }
}

Future<void> updatePost(
  int id,
  String title,
  String content,
  int categoryId,
) async {
  final response = await http.put(
    Uri.parse('$baseUrl/posts/$id'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'title': title,
      'content': content,
      'category_id': categoryId,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Gagal memperbarui artikel');
  }
}
}