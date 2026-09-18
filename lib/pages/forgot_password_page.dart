import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final ApiService _api = ApiService();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _success = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    String? error;

    if (email.isEmpty) {
      error = 'Email wajib diisi';
    } else if (!email.contains('@') || !email.contains('.')) {
      error = 'Format email tidak valid';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      error = 'Format email tidak valid';
    }

    setState(() => _emailError = error);
    return error == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _api.forgotPassword(email: _emailController.text.trim());

      if (!mounted) return;
      setState(() {
        _success = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
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
          'Lupa Password',
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
            child: _success ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
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
            Icons.mail_outline_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Lupa Password?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Masukkan email akun kamu untuk mendapatkan instruksi reset password.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        const FieldLabel('Email'),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          enabled: !_isLoading,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          cursorColor: AppColors.accent,
          decoration: appInputDecoration(
            hint: 'contoh@email.com',
            hasError: _emailError != null,
          ),
          onSubmitted: (_) => _submit(),
        ),
        FieldError(message: _emailError),
        const SizedBox(height: 28),
        primaryButton(
          label: 'Kirim Instruksi',
          loading: _isLoading,
          onPressed: _submit,
          icon: Icons.send_outlined,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(
              'Kembali ke Login',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.textPrimary,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Instruksi Reset Password',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Jika email terdaftar, instruksi reset password akan diproses.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 10),
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
              Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Untuk pengembangan saat ini, link reset dengan token tersedia di console backend (PASSWORD_RESET_URL?token=<raw_token>). Buka link tersebut untuk melanjutkan reset.',
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
        const SizedBox(height: 24),
        primaryButton(
          label: 'Kembali ke Login',
          onPressed: () => Navigator.pop(context),
          icon: Icons.arrow_back_rounded,
        ),
      ],
    );
  }
}
