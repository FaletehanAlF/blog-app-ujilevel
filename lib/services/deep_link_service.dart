import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../pages/reset_password_page.dart';

/// DeepLink khusus untuk alur Reset Password NARATA.
///
/// Mendukung:
/// - http://localhost:3000/reset-password?token=RAW
/// - https://domain.com/reset-password?token=RAW
/// - custom polling tidak diperlukan, cukup app_links
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Mencegah URI yang sama diproses berulang (initial + stream bisa dobel).
  String? _lastHandledUri;

  /// Global navigator agar bisa push dari service tanpa context lokal.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Initial link (app dari terminated)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (_) {
      // Abaikan error initial link, app tetap jalan
    }

    // 2. Runtime link (app sudah terbuka)
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (_) {},
    );
  }

  void _handleUri(Uri uri) {
    // Hanya path /reset-password
    // Gunakan Uri.parse, bukan split manual
    if (uri.path != '/reset-password') return;

    final token = uri.queryParameters['token'];
    if (token == null || token.trim().isEmpty) return;

    final normalized = uri.toString();
    if (_lastHandledUri == normalized) return;
    _lastHandledUri = normalized;

    // Cegah duplikasi cepat: reset flag setelah delay
    Future.delayed(const Duration(seconds: 2), () {
      _lastHandledUri = null;
    });

    _openResetPage(token.trim());
  }

  void _openResetPage(String token) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      // Navigator belum siap (misal init terlalu dini), tunda sebentar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(token: token),
          ),
        );
      });
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(token: token),
      ),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
