import 'dart:async';

import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

/// Halaman verifikasi email tahap 8.
///
/// Dibuka dari [login_page] saat `POST /auth/login` mengembalikan HTTP 403
/// ([EmailNotVerifiedException]). Menerima email lewat constructor agar
/// tidak perlu diketik ulang saat `POST /auth/resend-verification`.
///
/// Tahap ini TIDAK membuat auto-polling status verifikasi dan TIDAK
/// menangani deep link — hanya resend + cooldown 60 detik.
class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final ApiService _api = ApiService();

  /// Cooldown tombol resend dalam detik (backend-friendly, anti spam klik).
  static const int _cooldownDuration = 60;

  bool _isLoading = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  String? _resultMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    // Batalkan timer agar tidak setState setelah halaman dibuang
    // (mencegah memory leak / "setState called after dispose").
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    super.dispose();
  }

  bool get _canResend => !_isLoading && _cooldownSeconds <= 0;

  Future<void> _resend() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _resultMessage = null;
    });

    try {
      await _api.resendVerification(email: widget.email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _resultMessage =
            'Jika email terdaftar dan belum diverifikasi, link verifikasi telah dikirim.';
      });
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _resultMessage = msg;
      });
    }
  }

  /// Menjalankan cooldown 60 detik setelah resend berhasil.
  /// Selama countdown tombol nonaktif dan menampilkan sisa detik.
  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = _cooldownDuration);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 21),
        ),
        title: const Text(
          'Verifikasi Email',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
          24,
          MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verifikasi Email',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Email kamu belum diverifikasi, jadi login belum bisa dilanjutkan. '
                  'Silakan cek email untuk melakukan verifikasi.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cek kotak masuk (inbox) dan folder spam/promosi. '
                          'Klik link verifikasi di email tersebut, lalu login kembali.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_resultMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isSuccess
                          ? AppColors.surface
                          : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _isSuccess
                            ? AppColors.border
                            : AppColors.dangerBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isSuccess
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          size: 16,
                          color: _isSuccess
                              ? AppColors.accent
                              : AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _resultMessage!,
                            style: TextStyle(
                              color: _isSuccess
                                  ? AppColors.textPrimary
                                  : AppColors.danger,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                primaryButton(
                  label: 'Kirim Ulang Email',
                  loading: _isLoading,
                  onPressed: _canResend ? _resend : null,
                  icon: Icons.send_outlined,
                ),
                if (_cooldownSeconds > 0) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Kirim ulang dalam $_cooldownSeconds detik',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pop(context),
                    child: Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
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
