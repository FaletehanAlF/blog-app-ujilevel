import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'pages/email_verification_page.dart';
import 'pages/login_page.dart';
import 'pages/main_shell.dart';
import 'services/api.dart';
import 'services/deep_link_service.dart';
import 'widgets/app_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');

  // Load token dari SharedPreferences sebelum app dibuka
  // agar Dio interceptor bisa langsung mengirim Authorization header
  final api = ApiService();
  await api.init();

  // Inisialisasi deep link setelah binding ready, sebelum runApp
  // agar initial link sempat dibaca. NavigatorKey dipasang di BlogApp.
  // Jangan await blocking agar splash tetap cepat; cukup init async.
  // ignore: unawaited_futures
  DeepLinkService.instance.init();

  runApp(const BlogApp());
}

ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B0B0B),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF5F5F5),
      onPrimary: Color(0xFF0B0B0B),
      surface: Color(0xFF0B0B0B),
      error: Color(0xFFE5484D),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0B0B),
      foregroundColor: Color(0xFFF5F5F5),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFF5F5F5),
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
  );
}

class BlogApp extends StatelessWidget {
  const BlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RuangKata',
      theme: _buildTheme(),
      navigatorKey: DeepLinkService.instance.navigatorKey,
      home: const AuthGate(),
    );
  }
}

/// Menentukan halaman awal aplikasi.
/// - Tanpa token -> LoginPage (tanpa request).
/// - Token ada -> validasi via GET /auth/me (tahap 10):
///   verified -> MainShell, unverified -> EmailVerificationPage,
///   401 -> token dihapus lalu LoginPage.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiService _api = ApiService();
  bool _checking = true;
  bool _loggedIn = false;

  /// Email user yang tokennya valid tetapi belum verifikasi.
  /// Non-null -> AuthGate membuka EmailVerificationPage (tahap 10).
  String? _unverifiedEmail;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await _api.init();

    // Tanpa token -> Login, tanpa request (perilaku existing).
    if (!await _api.isLoggedIn()) {
      if (!mounted) return;
      setState(() => _checking = false);
      return;
    }

    // Token ada -> validasi session + status verifikasi via GET /auth/me.
    try {
      final me = await _api.getMe();

      if (!mounted) return;

      if (_isVerified(me)) {
        setState(() {
          _loggedIn = true;
          _checking = false;
        });
        return;
      }

      // Token valid tetapi email belum diverifikasi -> halaman verifikasi
      // dengan email dari response /auth/me (fallback cache lokal).
      final email = me['email']?.toString() ?? await _api.getEmail() ?? '';

      if (!mounted) return;

      // Tanpa email yang valid halaman verifikasi tak bisa dipakai
      // (butuh email untuk resend) -> fallback alur session normal.
      if (email.isEmpty) {
        setState(() {
          _loggedIn = true;
          _checking = false;
        });
        return;
      }

      setState(() {
        _unverifiedEmail = email;
        _checking = false;
      });
    } on UnauthorizedException catch (_) {
      // HTTP 401: token invalid/kedaluwarsa -> hapus session, ke Login.
      await _api.logout();
      if (!mounted) return;
      setState(() => _checking = false);
    } catch (_) {
      // Network error / response tak terduga: pertahankan perilaku existing
      // (token ada -> MainShell) agar user valid tak ter-logout saat offline.
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textMuted,
            ),
          ),
        ),
      );
    }
    final unverifiedEmail = _unverifiedEmail;
    if (unverifiedEmail != null) {
      return EmailVerificationPage(email: unverifiedEmail);
    }
    return _loggedIn ? const MainShell() : const LoginPage();
  }
}

/// Membaca status verifikasi dari response GET /auth/me.
/// Backend mengirim `data.is_verified` dan `data.email_verified_at`.
/// Robust terhadap varian tipe (bool/int/string) + fallback verified_at.
bool _isVerified(Map<String, dynamic> me) {
  final raw = me['is_verified'] ?? me['isVerified'];

  if (raw is bool) return raw;
  if (raw is num) return raw == 1;
  if (raw is String) {
    final normalized = raw.toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }

  final verifiedAt = me['email_verified_at'] ?? me['emailVerifiedAt'];
  if (verifiedAt != null && verifiedAt.toString().isNotEmpty) {
    return true;
  }

  return false;
}
