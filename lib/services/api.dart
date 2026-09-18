import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';
import '../models/category.dart';
import '../models/notification.dart';
import '../models/statistics.dart';

/// Urutan artikel yang didukung backend pada `GET /posts`.
///
/// Nilai dikirim apa adanya sebagai query parameter `sort`.
/// Urutan data ditentukan backend; Flutter tidak mengurutkan ulang.
enum PostSort {
  latest('latest', 'Terbaru'),
  oldest('oldest', 'Terlama'),
  titleAsc('title_asc', 'Judul A-Z'),
  titleDesc('title_desc', 'Judul Z-A');

  const PostSort(this.value, this.label);

  final String value;
  final String label;
}

class ApiService {
  static String get baseUrl => dotenv.env['API_URL'] ?? '';

  // =========================
  // SharedPreferences Keys
  // =========================

  static const String _kToken = 'jwt_token';
  static const String _kRole = 'user_role';
  static const String _kEmail = 'user_email';
  static const String _kId = 'user_id';
  static const String _kName = 'user_name';

  // =========================
  // Session
  // =========================

  static String? _token;
  static String? _role;
  static String? _email;
  static int? _userId;
  static String? _name;

  // =========================
  // Dio
  // =========================

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
        onRequest: (options, handler) {
          if (baseUrl.isNotEmpty) {
            _dio.options.baseUrl = baseUrl;
            options.baseUrl = baseUrl;
          }

          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }

          handler.next(options);
        },
      ),
    );
  }

  // =========================
  // Session Helpers
  // =========================

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString(_kToken);
    _role = prefs.getString(_kRole);
    _email = prefs.getString(_kEmail);
    _userId = prefs.getInt(_kId);
    _name = prefs.getString(_kName);
  }

  Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) {
      return _token;
    }

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);

    return _token;
  }

  Future<String?> getRole() async {
    if (_role != null) {
      return _role;
    }

    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString(_kRole);

    return _role;
  }

  Future<String?> getEmail() async {
    if (_email != null) {
      return _email;
    }

    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString(_kEmail);

    return _email;
  }

  Future<int?> getUserId() async {
    if (_userId != null) {
      return _userId;
    }

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt(_kId);

    return _userId;
  }

  Future<String?> getUserName() async {
    if (_name != null) {
      return _name;
    }

    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString(_kName);

    return _name;
  }

  String? get token => _token;
  String? get role => _role;
  String? get email => _email;
  int? get userId => _userId;
  String? get userName => _name;

  Future<bool> isLoggedIn() async {
    final currentToken = await getToken();

    return currentToken != null && currentToken.isNotEmpty;
  }

  bool get isLoggedInSync {
    return _token != null && _token!.isNotEmpty;
  }

  // =========================
  // JWT
  // =========================

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      String payload = parts[1];

      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final remainder = payload.length % 4;

      if (remainder == 2) {
        payload += '==';
      } else if (remainder == 3) {
        payload += '=';
      } else if (remainder != 0) {
        return null;
      }

      final decoded = utf8.decode(
        base64.decode(payload),
      );

      final data = jsonDecode(decoded);

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================
  // Save Auth Data
  // =========================

  Future<void> _saveAuthData(
    String token, {
    String? role,
    String? email,
    int? id,
    String? name,
  }) async {
    final payload = _decodeJwt(token);

    if (payload != null) {
      role ??= payload['role']?.toString();
      email ??= payload['email']?.toString();
      name ??=
          payload['name']?.toString() ??
          payload['username']?.toString() ??
          payload['user']?.toString();

      final rawId =
          payload['id'] ??
          payload['userId'] ??
          payload['user_id'];

      if (id == null && rawId != null) {
        id = int.tryParse(rawId.toString());
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

  // =========================
  // Error Handler
  // =========================

  String _extractDioError(DioException e) {
    final response = e.response;

    if (response?.data != null) {
      final data = response!.data;

      if (data is Map) {
        final message = data['message'];

        if (message != null) {
          return message.toString();
        }

        final error = data['error'];

        if (error != null) {
          return error.toString();
        }

        final errors = data['errors'];

        if (errors != null) {
          return errors.toString();
        }
      }

      if (data is String && data.isNotEmpty) {
        return data;
      }
    }

    if (response?.statusCode != null) {
      switch (response!.statusCode) {
        case 401:
          return 'Email atau password salah, atau sesi habis.';
        case 403:
          return 'Akses ditolak. Periksa role akun.';
        case 404:
          return 'Data tidak ditemukan.';
        case 422:
          return 'Data tidak valid. Periksa input.';
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa koneksi atau API_URL.';

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa API_URL di assets/.env dan pastikan backend berjalan.';

      default:
        break;
    }

    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }

    return 'Terjadi kesalahan jaringan.';
  }

  // =========================
  // Authentication
  // =========================

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

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'Login gagal: ${response.statusCode}',
        );
      }

      final data = response.data;

      if (data is! Map) {
        throw Exception(
          'Response login tidak valid.',
        );
      }

      String? token;
      String? role;
      String? responseEmail;
      String? name;
      int? id;

      token =
          data['token']?.toString() ??
          data['accessToken']?.toString() ??
          data['access_token']?.toString();

      dynamic nestedData = data['data'];

      if (token == null && nestedData is Map) {
        token =
            nestedData['token']?.toString() ??
            nestedData['accessToken']?.toString() ??
            nestedData['access_token']?.toString();
      }

      dynamic user = data['user'];

      if (user == null && nestedData is Map) {
        user = nestedData['user'];

        if (user == null &&
            (nestedData['email'] != null ||
                nestedData['role'] != null ||
                nestedData['id'] != null)) {
          user = nestedData;
        }
      }

      if (user is Map) {
        role = user['role']?.toString();

        responseEmail = user['email']?.toString();

        name =
            user['name']?.toString() ??
            user['username']?.toString() ??
            user['nama']?.toString();

        final rawId =
            user['id'] ??
            user['userId'] ??
            user['user_id'];

        if (rawId != null) {
          id = int.tryParse(rawId.toString());
        }
      }

      role ??= data['role']?.toString();
      responseEmail ??= data['email']?.toString();
      name ??= data['name']?.toString();

      if (id == null && data['id'] != null) {
        id = int.tryParse(
          data['id'].toString(),
        );
      }

      if (token == null || token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan pada response server.',
        );
      }

      await _saveAuthData(
        token,
        role: role,
        email: responseEmail ?? email,
        id: id,
        name: name,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

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

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'Registrasi gagal: ${response.statusCode}',
        );
      }

      final data = response.data;

      if (data is! Map) {
        return;
      }

      String? token;

      token =
          data['token']?.toString() ??
          data['accessToken']?.toString() ??
          data['access_token']?.toString();

      final nestedData = data['data'];

      if (token == null && nestedData is Map) {
        token =
            nestedData['token']?.toString() ??
            nestedData['accessToken']?.toString() ??
            nestedData['access_token']?.toString();
      }

      // Backend boleh mengembalikan token setelah register.
      // Jika tidak, user cukup diarahkan ke halaman login.
      if (token == null || token.isEmpty) {
        return;
      }

      String? role;
      String? responseEmail;
      String? responseName;
      int? id;

      dynamic user = data['user'];

      if (user == null && nestedData is Map) {
        user = nestedData['user'];
        user ??= nestedData;
      }

      if (user is Map) {
        role = user['role']?.toString();
        responseEmail = user['email']?.toString();

        responseName =
            user['name']?.toString() ??
            user['username']?.toString();

        final rawId =
            user['id'] ??
            user['userId'] ??
            user['user_id'];

        if (rawId != null) {
          id = int.tryParse(
            rawId.toString(),
          );
        }
      }

      await _saveAuthData(
        token,
        role: role ?? data['role']?.toString(),
        email:
            responseEmail ??
            data['email']?.toString() ??
            email,
        id: id,
        name:
            responseName ??
            data['name']?.toString() ??
            name,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

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

  // =========================
  // Posts
  // =========================

  Future<List<Post>> getPosts({String? search}) async {
    try {
      final response = await _dio.get(
        '/posts',
        queryParameters: search != null && search.trim().isNotEmpty
            ? {'search': search.trim()}
            : null,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data artikel.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return [];
      }

      final data = body['data'];

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => Post.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// Daftar artikel dengan pagination backend.
  ///
  /// Memanggil `GET /posts?page=X&limit=Y` (plus `search` dan `sort`
  /// jika ada) dan membaca metadata dari
  /// `pagination: {page, limit, total, totalPages}`.
  /// Tanpa parameter page/limit, backend tidak mengirim metadata, jadi
  /// method ini selalu mengirim keduanya agar respons konsisten.
  /// Contoh: `GET /posts?search=teknologi&sort=title_asc&page=1&limit=10`.
  Future<PaginatedPosts> getPostsPaginated({
    String? search,
    PostSort sort = PostSort.latest,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort.value,
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParameters['search'] = search.trim();
      }

      final response = await _dio.get(
        '/posts',
        queryParameters: queryParameters,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data artikel.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return PaginatedPosts(
          posts: const [],
          page: page,
          limit: limit,
          total: 0,
          totalPages: page,
        );
      }

      final rawData = body['data'];

      final List<Post> posts;

      if (rawData is List) {
        posts = rawData
            .whereType<Map>()
            .map(
              (item) => Post.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      } else {
        posts = [];
      }

      final rawPagination = body['pagination'] is Map
          ? body['pagination'] as Map
          : (body['meta'] is Map ? body['meta'] as Map : null);

      if (rawPagination != null) {
        final meta = Map<String, dynamic>.from(rawPagination);

        return PaginatedPosts(
          posts: posts,
          page: _toInt(meta['page'] ?? meta['current_page']) ?? page,
          limit: _toInt(meta['limit'] ?? meta['per_page']) ?? limit,
          total: _toInt(meta['total']) ?? posts.length,
          totalPages: _toInt(meta['totalPages'] ?? meta['total_pages']) ?? 1,
        );
      }

      // Fallback jika backend tidak mengirim metadata: halaman terakhir
      // adalah halaman yang datanya kurang dari limit yang diminta.
      return PaginatedPosts(
        posts: posts,
        page: page,
        limit: limit,
        total: posts.length,
        totalPages: posts.length < limit ? page : page + 1,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  Future<Post> getPostById(int id) async {
    try {
      final response = await _dio.get(
        '/posts/$id',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil detail artikel.',
        );
      }

      final body = response.data;

      if (body is! Map || body['data'] is! Map) {
        throw Exception(
          'Response detail artikel tidak valid.',
        );
      }

      return Post.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// Mencatat satu view pada artikel dan mengembalikan view_count
  /// terbaru dari backend. Kepemilikan/rate-limit ditentukan backend
  /// via JWT.
  Future<int> addPostView(int postId) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/view',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal menambahkan view.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Response view tidak valid.',
        );
      }

      if (body['success'] == false) {
        final message = body['message']?.toString();

        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal menambahkan view.',
        );
      }

      final data = body['data'];

      if (data is Map) {
        final count = _toInt(data['view_count']);

        if (count != null && count >= 0) {
          return count;
        }
      }

      throw Exception(
        'Response view tidak valid.',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Bookmarks
  // =========================

  /// Bookmark milik user yang sedang login.
  /// Backend menentukan kepemilikan dari JWT, tanpa filter user
  /// secara hardcode di Flutter. Item daftar memakai struktur Post
  /// yang sudah ada (langsung atau nested di key `post`).

  Future<void> addBookmark(int postId) async {
    try {
      final response = await _dio.post(
        '/bookmarks/$postId',
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'Gagal menambahkan bookmark.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  Future<void> removeBookmark(int postId) async {
    try {
      final response = await _dio.delete(
        '/bookmarks/$postId',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal menghapus bookmark.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// True jika artikel sudah dibookmark user yang sedang login.
  /// 404 berarti belum dibookmark (bukan error); error lain
  /// (mis. 401 sesi habis) tetap dilempar agar tidak disamarkan.
  Future<bool> getBookmarkStatus(int postId) async {
    try {
      final response = await _dio.get(
        '/bookmarks/$postId',
      );

      if (response.statusCode != 200) {
        return false;
      }

      final body = response.data;

      if (body is! Map) {
        return false;
      }

      final data = body['data'];

      for (final source in [data, body]) {
        if (source is Map) {
          final flag = source['bookmarked'] ??
              source['is_bookmarked'] ??
              source['isBookmarked'];

          if (flag is bool) {
            return flag;
          }

          if (flag != null) {
            final normalized = flag.toString().toLowerCase();

            if (normalized == 'true' || normalized == '1') {
              return true;
            }

            if (normalized == 'false' || normalized == '0') {
              return false;
            }
          }
        } else if (source is bool) {
          return source;
        }
      }

      // Payload data non-kosong tanpa flag eksplisit (mis. detail
      // bookmark {id, post_id, ...}) berarti sudah dibookmark.
      if (data is Map && data.isNotEmpty) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }

      throw Exception(
        _extractDioError(e),
      );
    }
  }

  Future<PaginatedPosts> getBookmarks({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/bookmarks',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data bookmark.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return PaginatedPosts(
          posts: const [],
          page: page,
          limit: limit,
          total: 0,
          totalPages: page,
        );
      }

      final rawData = body['data'];

      final List<Post> posts = [];

      if (rawData is List) {
        for (final item in rawData.whereType<Map>()) {
          final map = Map<String, dynamic>.from(item);

          // Item bisa berupa Post langsung atau wrapper {post: {...}}.
          final postJson = map['post'] is Map
              ? Map<String, dynamic>.from(map['post'] as Map)
              : map;

          posts.add(Post.fromJson(postJson));
        }
      }

      final rawPagination = body['pagination'] is Map
          ? body['pagination'] as Map
          : (body['meta'] is Map ? body['meta'] as Map : null);

      if (rawPagination != null) {
        final meta = Map<String, dynamic>.from(rawPagination);

        return PaginatedPosts(
          posts: posts,
          page: _toInt(meta['page'] ?? meta['current_page']) ?? page,
          limit: _toInt(meta['limit'] ?? meta['per_page']) ?? limit,
          total: _toInt(meta['total']) ?? posts.length,
          totalPages: _toInt(meta['totalPages'] ?? meta['total_pages']) ?? 1,
        );
      }

      // Fallback jika backend tidak mengirim metadata: halaman terakhir
      // adalah halaman yang datanya kurang dari limit yang diminta.
      return PaginatedPosts(
        posts: posts,
        page: page,
        limit: limit,
        total: posts.length,
        totalPages: posts.length < limit ? page : page + 1,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Likes
  // =========================

  /// Tambah Like pada artikel. Kepemilikan ditentukan backend via JWT.
  Future<void> addLike(int postId) async {
    try {
      final response = await _dio.post(
        '/likes/$postId',
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          'Gagal menambahkan like.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  Future<void> removeLike(int postId) async {
    try {
      final response = await _dio.delete(
        '/likes/$postId',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal menghapus like.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// True jika artikel sudah di-like user yang sedang login.
  /// 404 berarti belum di-like (bukan error); error lain
  /// (mis. 401 sesi habis) tetap dilempar.
  Future<bool> getLikeStatus(int postId) async {
    try {
      final response = await _dio.get(
        '/likes/$postId',
      );

      if (response.statusCode != 200) {
        return false;
      }

      final body = response.data;

      if (body is! Map) {
        return false;
      }

      final data = body['data'];

      for (final source in [data, body]) {
        if (source is Map) {
          final flag = source['liked'] ??
              source['is_liked'] ??
              source['isLiked'];

          if (flag is bool) {
            return flag;
          }

          if (flag != null) {
            final normalized = flag.toString().toLowerCase();

            if (normalized == 'true' || normalized == '1') {
              return true;
            }

            if (normalized == 'false' || normalized == '0') {
              return false;
            }
          }
        } else if (source is bool) {
          return source;
        }
      }

      if (data is Map && data.isNotEmpty) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return false;
      }

      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// Daftar artikel yang di-like user yang sedang login.
  /// Backend menentukan kepemilikan dari JWT.
  Future<PaginatedPosts> getLikes({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/likes',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data like.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return PaginatedPosts(
          posts: const [],
          page: page,
          limit: limit,
          total: 0,
          totalPages: page,
        );
      }

      final rawData = body['data'];

      final List<Post> posts = [];

      if (rawData is List) {
        for (final item in rawData.whereType<Map>()) {
          final map = Map<String, dynamic>.from(item);

          // Item bisa berupa Post langsung atau wrapper {post: {...}}.
          final postJson = map['post'] is Map
              ? Map<String, dynamic>.from(map['post'] as Map)
              : map;

          posts.add(Post.fromJson(postJson));
        }
      }

      final rawPagination = body['pagination'] is Map
          ? body['pagination'] as Map
          : (body['meta'] is Map ? body['meta'] as Map : null);

      if (rawPagination != null) {
        final meta = Map<String, dynamic>.from(rawPagination);

        return PaginatedPosts(
          posts: posts,
          page: _toInt(meta['page'] ?? meta['current_page']) ?? page,
          limit: _toInt(meta['limit'] ?? meta['per_page']) ?? limit,
          total: _toInt(meta['total']) ?? posts.length,
          totalPages: _toInt(meta['totalPages'] ?? meta['total_pages']) ?? 1,
        );
      }

      // Fallback jika backend tidak mengirim metadata.
      return PaginatedPosts(
        posts: posts,
        page: page,
        limit: limit,
        total: posts.length,
        totalPages: posts.length < limit ? page : page + 1,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Notifications
  // =========================

  /// Notifikasi milik user yang sedang login.
  /// Backend menentukan kepemilikan dari JWT, tanpa filter user
  /// secara hardcode di Flutter.
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(
        '/notifications',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data notifikasi.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return [];
      }

      if (body['success'] == false) {
        final message = body['message']?.toString();

        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal mengambil data notifikasi.',
        );
      }

      final data = body['data'];

      if (data is! List) {
        return [];
      }

      return data
          .whereType<Map>()
          .map(
            (item) => NotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// Jumlah notifikasi yang belum dibaca milik user yang sedang login.
  /// Backend menentukan kepemilikan dari JWT, tanpa filter user
  /// secara hardcode di Flutter. Gagal parsing aman: fallback 0.
  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get(
        '/notifications/unread-count',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil jumlah notifikasi.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return 0;
      }

      if (body['success'] == false) {
        final message = body['message']?.toString();

        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal mengambil jumlah notifikasi.',
        );
      }

      final data = body['data'];

      if (data is Map) {
        final count = _toInt(data['count']);

        if (count == null || count < 0) {
          return 0;
        }

        return count;
      }

      return 0;
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// Menandai semua notifikasi user yang sedang login sebagai dibaca.
  /// Backend menentukan kepemilikan dari JWT, tanpa filter user
  /// secara hardcode di Flutter.
  Future<void> markAllNotificationsAsRead() async {
    try {
      final response = await _dio.patch(
        '/notifications/read-all',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal menandai notifikasi sebagai dibaca.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return;
      }

      if (body['success'] == false) {
        final message = body['message']?.toString();

        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal menandai notifikasi sebagai dibaca.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Create Post
  // =========================

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
        final bytes = await image.readAsBytes();

        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              bytes,
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
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Update Post
  // =========================

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
        final bytes = await image.readAsBytes();

        formData.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(
              bytes,
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
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Delete Post
  // =========================

  Future<void> deletePost(int id) async {
    try {
      final response = await _dio.delete(
        '/posts/$id',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal menghapus artikel.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Profile
  // =========================

  /// Profil user yang sedang login beserta jumlah artikel miliknya.
  /// Daftar "Artikel Saya" difilter client-side dari getPosts()
  /// memakai posts.user_id == userId.
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get(
        '/auth/me',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil profil.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Response profil tidak valid.',
        );
      }

      final data = body['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'Response profil tidak valid.',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// Profil publik user lain beserta daftar artikelnya.
  /// Hanya data publik yang dipakai UI (nama, foto, jumlah artikel,
  /// daftar artikel); tidak ada password/JWT di response backend.
  Future<Map<String, dynamic>> getPublicProfile(int userId) async {
    try {
      final response = await _dio.get(
        '/profile/$userId',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil profil pengguna.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Response profil tidak valid.',
        );
      }

      if (body['success'] == false) {
        final message = body['message']?.toString();

        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal mengambil profil pengguna.',
        );
      }

      final data = body['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'Response profil tidak valid.',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  /// Memperbarui nama dan/atau foto profil user yang sedang login.
  /// Foto dikirim multipart seperti upload gambar artikel; update nama
  /// saja tetap bisa tanpa memilih foto. Kepemilikan ditentukan
  /// backend via JWT. Cache nama lokal disegarkan agar tampilan
  /// aplikasi langsung konsisten tanpa auth ulang.
  Future<void> updateProfile({
    required String name,
    XFile? profileImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
      });

      if (profileImage != null) {
        final bytes = await profileImage.readAsBytes();

        formData.files.add(
          MapEntry(
            'profile_image',
            MultipartFile.fromBytes(
              bytes,
              filename: profileImage.name,
            ),
          ),
        );
      }

      final response = await _dio.put(
        '/profile',
        data: formData,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal memperbarui profil.',
        );
      }

      final body = response.data;

      if (body is Map && body['success'] == false) {
        final message = body['message']?.toString();

        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal memperbarui profil.',
        );
      }

      _name = name;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_kName, name);
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Categories
  // =========================

  /// Kategori milik user yang sedang login.
  /// Backend memfilter berdasarkan JWT, jadi tidak ada kategori user lain.
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get(
        '/categories',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data kategori.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        return [];
      }

      final data = body['data'];

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => Category.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  Future<void> createCategory(
    String name,
  ) async {
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
      throw Exception(
        _extractDioError(e),
      );
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
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  Future<void> deleteCategory(
    int id,
  ) async {
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
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Change Password
  // =========================

  /// Mengubah password user yang sedang login.
  /// Backend memvalidasi via JWT dan field current/new/confirm.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengubah password.',
        );
      }

      final body = response.data;

      if (body is Map && body['success'] == false) {
        final message = body['message']?.toString();
        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal mengubah password.',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }

  // =========================
  // Statistics
  // =========================

  /// Statistik milik user yang sedang login.
  /// Backend menentukan kepemilikan dari JWT via `GET /statistics`.
  /// Response: `{success: true, data: {total_articles, total_views,
  /// total_likes, total_bookmarks}}`.
  Future<Statistics> getStatistics() async {
    try {
      final response = await _dio.get(
        '/statistics',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil statistik.',
        );
      }

      final body = response.data;

      if (body is! Map) {
        throw Exception(
          'Response statistik tidak valid.',
        );
      }

      if (body['success'] == false) {
        final message = body['message']?.toString();
        throw Exception(
          message != null && message.isNotEmpty
              ? message
              : 'Gagal mengambil statistik.',
        );
      }

      final data = body['data'];

      if (data is! Map) {
        throw Exception(
          'Response statistik tidak valid.',
        );
      }

      return Statistics.fromJson(
        Map<String, dynamic>.from(data),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioError(e),
      );
    }
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
