import 'package:flutter/material.dart';
import 'package:belajar_flutter/pages/login_page.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final ApiService _api = ApiService();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    String? newError;
    String? confirmError;

    if (newPass.isEmpty) {
      newError = 'Password baru wajib diisi';
    } else if (newPass.length < 8) {
      newError = 'Password baru minimal 8 karakter';
    }

    if (confirm.isEmpty) {
      confirmError = 'Konfirmasi password wajib diisi';
    } else if (confirm != newPass) {
      confirmError = 'Konfirmasi password harus sama dengan password baru';
    }

    setState(() {
      _newError = newError;
      _confirmError = confirmError;
    });

    return newError == null && confirmError == null;
  }

  String _mapTokenError(String raw) {
    final lower = raw.toLowerCase();
    final isTokenError = lower.contains('token') &&
        (lower.contains('invalid') ||
            lower.contains('expired') ||
            lower.contains('kedaluwarsa') ||
            lower.contains('tidak valid') ||
            lower.contains('sudah digunakan') ||
            lower.contains('already used'));
    if (isTokenError) {
      return 'Token reset password tidak valid atau sudah kedaluwarsa';
    }
    return raw;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _api.resetPassword(
        token: widget.token,
        newPassword: _newController.text,
        confirmPassword: _confirmController.text,
      );

      if (!mounted) return;

      showAppSnack(context, 'Password berhasil direset');

      // Hapus stack reset agar token sekali pakai tidak bisa di-back
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      var msg = e.toString().replaceFirst('Exception: ', '');
      msg = _mapTokenError(msg);
      setState(() => _isLoading = false);
      showAppSnack(context, msg, isError: true);
    }
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
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                    Icons.lock_reset_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Atur password baru',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan password baru minimal 8 karakter dan konfirmasi kembali.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                const FieldLabel('Password Baru'),
                const SizedBox(height: 8),
                TextField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Minimal 8 karakter',
                    hasError: _newError != null,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                FieldError(message: _newError),
                const SizedBox(height: 20),
                const FieldLabel('Konfirmasi Password Baru'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Ulangi password baru',
                    hasError: _confirmError != null,
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                FieldError(message: _confirmError),
                const SizedBox(height: 28),
                primaryButton(
                  label: 'Reset Password',
                  loading: _isLoading,
                  onPressed: _submit,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
