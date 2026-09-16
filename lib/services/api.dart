import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  // Kunci SharedPreferences - jangan hardcode token di source code
  static const String _kToken = 'jwt_token';
  static const String _kRole = 'user_role';
  static const String _kEmail = 'user_email';
  static const String _kId = 'user_id';
  static const String _kName = 'user_name';

  static String? _token;
  static String? _role;
  static String? _email;
  static int? _userId;
  static String? _name;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Pastikan baseUrl selalu terupdate dari .env (dotenv.load bisa terlambat)
          if (_dio.options.baseUrl.isEmpty && baseUrl.isNotEmpty) {
            _dio.options.baseUrl = baseUrl;
            options.baseUrl = baseUrl;
          } else if (_dio.options.baseUrl != baseUrl && baseUrl.isNotEmpty) {
            _dio.options.baseUrl = baseUrl;
            options.baseUrl = baseUrl;
          }

          // Kirim token jika ada
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ========== Token & Session Helpers ==========

  /// Load token & role dari SharedPreferences ke memory.
  /// Harus dipanggil sekali saat aplikasi dijalankan (di main.dart).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _role = prefs.getString(_kRole);
    _email = prefs.getString(_kEmail);
    _userId = prefs.getInt(_kId);
    _name = prefs.getString(_kName);
  }

  /// Ambil token, coba load dari prefs jika memory masih kosong.
  Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    return _token;
  }

  Future<String?> getRole() async {
    if (_role != null) return _role;
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString(_kRole);
    return _role;
  }

  Future<String?> getEmail() async {
    if (_email != null) return _email;
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_kEmail);
    return _email;
  }

  Future<int?> getUserId() async {
    if (_userId != null) return _userId;
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt(_kId);
    return _userId;
  }

  Future<String?> getUserName() async {
    if (_name != null) return _name;
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_kName);
    return _name;
  }

  // Getter sync untuk kebutuhan UI tanpa async
  String? get token => _token;
  String? get role => _role;
  String? get email => _email;
  int? get userId => _userId;
  String? get userName => _name;

  Future<bool> isLoggedIn() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  bool get isLoggedInSync => _token != null && _token!.isNotEmpty;

  /// Decode payload JWT sederhana tanpa library tambahan.
  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String payload = parts[1];
      // base64Url -> base64
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
        default:
          return null;
      }
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) return map;
      if (map is Map) return Map<String, dynamic>.from(map);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAuthData(
    String token, {
    String? role,
    String? email,
    int? id,
    String? name,
  }) async {
    // Coba decode JWT jika role/email/id masih kosong
    if ((role == null || email == null || id == null) &&
        token.split('.').length == 3) {
      final payload = _decodeJwt(token);
      if (payload != null) {
        role ??= payload['role']?.toString();
        email ??= payload['email']?.toString();
        // id bisa bernama id, userId, user_id
        final rawId = payload['id'] ?? payload['userId'] ?? payload['user_id'];
        if (id == null && rawId != null) {
          if (rawId is int) {
            id = rawId;
          } else {
            id = int.tryParse(rawId.toString());
          }
        }
        name ??= payload['name']?.toString() ??
            payload['username']?.toString() ??
            payload['user']?.toString();
      }
    }

    _token = token;
    _role = role;
    _email = email;
    _userId = id;
    _name = name;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    if (role != null) {
      await prefs.setString(_kRole, role);
    }
    if (email != null) {
      await prefs.setString(_kEmail, email);
    }
    if (id != null) {
      await prefs.setInt(_kId, id);
    }
    if (name != null) {
      await prefs.setString(_kName, name);
    }
  }

  String _extractDioError(DioException e) {
    // Coba ambil pesan dari response backend
    if (e.response != null && e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map) {
        if (d['message'] != null) return d['message'].toString();
        if (d['error'] != null) return d['error'].toString();
        if (d['msg'] != null) return d['msg'].toString();
        if (d['errors'] != null) return d['errors'].toString();
        if (d['data'] is Map) {
          final inner = d['data'] as Map;
          if (inner['message'] != null) return inner['message'].toString();
          if (inner['error'] != null) return inner['error'].toString();
        }
      } else if (d is String && d.isNotEmpty) {
        return d;
      }
      // status code info
      final code = e.response?.statusCode;
      if (code == 401) return 'Email atau password salah, atau sesi habis.';
      if (code == 403) return 'Akses ditolak. Periksa role akun.';
      if (code == 422) return 'Data tidak valid. Periksa input.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi timeout. Periksa koneksi atau API_URL.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server. Periksa API_URL di assets/.env dan pastikan backend berjalan.';
    }
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    return 'Terjadi kesalahan jaringan';
  }

  // ========== Auth ==========

  /// Login ke POST /auth/login dan simpan JWT.
  /// Mengirim {email, password}
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? token;
        String? role;
        String? resEmail;
        int? id;
        String? name;

        if (data is Map<String, dynamic>) {
          token = data['token']?.toString() ??
              data['accessToken']?.toString() ??
              data['access_token']?.toString() ??
              (data['data'] is Map ? (data['data']['token']?.toString() ?? data['data']['accessToken']?.toString()) : null);

          // Cari user object di berbagai bentuk response
          dynamic user = data['user'] ?? data['data']?['user'];
          // Jika data['data'] sendiri adalah user tanpa wrapper token
          if (user == null && data['data'] is Map && token == null) {
            // fallback: jika response data adalah user langsung
          }
          // Jika token ada di dalam data['data'] yang bukan user, user bisa terpisah
          if (user == null && data['data'] is Map && data['data']['user'] == null) {
            // cek apakah data['data'] berisi field user
            final maybeUser = data['data'];
            if (maybeUser is Map && (maybeUser['email'] != null || maybeUser['role'] != null)) {
              user = maybeUser;
            }
          }

          if (user is Map) {
            role = user['role']?.toString();
            resEmail = user['email']?.toString();
            final rawId = user['id'] ?? user['userId'] ?? user['user_id'];
            if (rawId is int) {
              id = rawId;
            } else if (rawId != null) {
              id = int.tryParse(rawId.toString());
            }
            name = user['name']?.toString() ??
                user['username']?.toString() ??
                user['nama']?.toString();
          }

          // Fallback role/email di top-level
          role ??= data['role']?.toString() ??
              (data['data'] is Map ? data['data']['role']?.toString() : null);
          resEmail ??= data['email']?.toString() ??
              (data['data'] is Map ? data['data']['email']?.toString() : null);
          if (id == null) {
            final rawId = data['id'] ?? (data['data'] is Map ? data['data']['id'] : null);
            if (rawId is int) {
              id = rawId;
            } else if (rawId != null) {
              id = int.tryParse(rawId.toString());
            }
          }
        }

        if (token == null || token.isEmpty) {
          throw Exception('Token tidak ditemukan pada response server');
        }

        await _saveAuthData(
          token,
          role: role,
          email: resEmail ?? email,
          id: id,
          name: name,
        );
        return;
      }
      throw Exception('Login gagal: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  /// Register ke POST /auth/register
  /// Mengirim {name, email, password}
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Jika backend langsung mengembalikan token setelah register, simpan juga
        String? token;
        String? role;
        String? resEmail;
        int? id;
        String? resName;

        if (data is Map<String, dynamic>) {
          token = data['token']?.toString() ??
              data['accessToken']?.toString() ??
              (data['data'] is Map ? (data['data']['token']?.toString() ?? data['data']['accessToken']?.toString()) : null);
          if (token != null && token.isNotEmpty) {
            dynamic user = data['user'] ?? data['data']?['user'] ?? data['data'];
            if (user is Map) {
              role = user['role']?.toString();
              resEmail = user['email']?.toString();
              final rawId = user['id'] ?? user['userId'];
              if (rawId is int) {
                id = rawId;
              } else if (rawId != null) {
                id = int.tryParse(rawId.toString());
              }
              resName = user['name']?.toString() ?? user['username']?.toString();
            }
            await _saveAuthData(
              token,
              role: role,
              email: resEmail ?? email,
              id: id,
              name: resName ?? name,
            );
          }
        }
        return;
      }
      throw Exception('Registrasi gagal: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  /// Hapus token & data user dari SharedPreferences
  Future<void> logout() async {
    _token = null;
    _role = null;
    _email = null;
    _userId = null;
    _name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kRole);
    await prefs.remove(_kEmail);
    await prefs.remove(_kId);
    await prefs.remove(_kName);
  }

  // ========== Posts ==========

  Future<List<Post>> getPosts() async {
    try {
      final response = await _dio.get('/posts');

      if (response.statusCode == 200) {
        return (response.data['data'] as List)
            .map((e) => Post.fromJson(e))
            .toList();
      }

      throw Exception('Gagal mengambil data artikel');
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  Future<Post> getPostById(int id) async {
    try {
      final response = await _dio.get('/posts/$id');

      if (response.statusCode == 200) {
        return Post.fromJson(response.data['data']);
      }

      throw Exception('Gagal mengambil detail artikel');
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  Future<void> createPost(
    String title,
    String content,
    int categoryId,
    XFile? image,
  ) async {
    try {
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
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  Future<void> updatePost(
    int id,
    String title,
    String content,
    int categoryId,
    XFile? image,
  ) async {
    try {
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
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  Future<void> deletePost(int id) async {
    try {
      final response = await _dio.delete('/posts/$id');

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus artikel');
      }
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  // ========== Categories ==========

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/categories');

      if (response.statusCode == 200) {
        return response.data['data'];
      }

      throw Exception('Gagal mengambil data kategori');
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  Future<void> createCategory(String name) async {
    try {
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
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  Future<void> updateCategory(
    int id,
    String name,
  ) async {
    try {
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
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final response = await _dio.delete(
        '/categories/$id',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal menghapus kategori: ${response.data}',
        );
      }
    } on DioException catch (e) {
      throw Exception(_extractDioError(e));
    }
  }
}
