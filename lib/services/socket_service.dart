import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/notification.dart';
import 'api.dart';

/// Callback untuk satu notifikasi realtime dari Socket.IO.
typedef NotificationCallback = void Function(
  NotificationModel notification,
);

/// Service Socket.IO untuk notifikasi realtime.
///
/// - Singleton: satu koneksi untuk seluruh aplikasi.
/// - URL memakai [ApiService.baseUrl] yang sudah ada (HTTP server
///   backend yang sama, tanpa URL baru).
/// - Auth memakai JWT dari mekanisme penyimpanan token existing
///   ([ApiService.getToken]) via `auth: {'token': jwt}`.
/// - Event yang didengarkan: `notification:new` dengan payload yang
///   sama seperti `GET /notifications`.
/// - Database tetap hanya ditulis backend; service ini hanya membaca
///   event dan meneruskannya ke listener lokal.
/// - Jika koneksi gagal/tidak tersedia, aplikasi tetap berjalan dengan
///   REST API seperti biasa (tidak pernah throw ke pemanggil UI).
class SocketService {
  SocketService._internal();

  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  static const String eventNew = 'notification:new';

  io.Socket? _socket;
  bool _connecting = false;

  final List<NotificationCallback> _listeners = [];

  bool get isConnected => _socket?.connected ?? false;

  /// Membuka koneksi Socket.IO satu kali.
  /// Aman dipanggil berulang: tidak membuat koneksi ganda.
  /// Tidak pernah throw; kegagalan koneksi diabaikan diam-diam agar
  /// REST API tetap menjadi fallback.
  Future<void> connect() async {
    if (isConnected || _connecting) return;

    // Socket lama masih ada (mis. reconnect otomatis library sedang
    // berjalan): cukup pastikan listener event terpasang satu kali.
    if (_socket != null) {
      try {
        _socket!
          ..off(eventNew)
          ..on(eventNew, _handleNew);
      } catch (_) {
        // Abaikan, REST API tetap berfungsi.
      }

      return;
    }

    _connecting = true;

    try {
      final token = await ApiService().getToken();
      final url = ApiService.baseUrl;

      // Tanpa token (belum login) atau tanpa base URL: jangan connect.
      if (token == null || token.isEmpty || url.isEmpty) {
        return;
      }

      _socket = io.io(
        url,
        <String, dynamic>{
          'transports': ['websocket', 'polling'],
          'autoConnect': false,
          'auth': {'token': token},
        },
      );

      _socket!
        ..on(eventNew, _handleNew)
        ..connect();
    } catch (_) {
      // Koneksi gagal: bersihkan agar percobaan berikutnya membuat
      // socket baru, aplikasi tetap memakai REST API.
      _disposeSocket();
    } finally {
      _connecting = false;
    }
  }

  /// Mendaftarkan penerima notifikasi realtime.
  /// Callback yang sama tidak didaftarkan dua kali.
  void addListener(NotificationCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  /// Melepas penerima notifikasi realtime.
  void removeListener(NotificationCallback callback) {
    _listeners.remove(callback);
  }

  /// Memutus koneksi dan membuang socket.
  /// Idempotent dan tidak pernah throw. Dipanggil saat logout dan
  /// saat pemilik service di-dispose.
  void disconnect() {
    try {
      _socket?.off(eventNew);
      _socket?.disconnect();
    } catch (_) {
      // Abaikan, lanjut ke dispose di bawah.
    } finally {
      _disposeSocket();
    }
  }

  void _handleNew(dynamic data) {
    try {
      if (data is! Map) return;

      final notification = NotificationModel.fromJson(
        Map<String, dynamic>.from(data),
      );

      for (final listener in List.of(_listeners)) {
        try {
          listener(notification);
        } catch (_) {
          // Satu listener gagal tidak boleh mematikan yang lain.
        }
      }
    } catch (_) {
      // Payload tidak valid: abaikan, jangan crash.
    }
  }

  void _disposeSocket() {
    try {
      _socket?.dispose();
    } catch (_) {
      // Abaikan.
    } finally {
      _socket = null;
    }
  }
}
