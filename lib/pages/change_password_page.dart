import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final ApiService _api = ApiService();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final current = _currentController.text;
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    String? currentError;
    String? newError;
    String? confirmError;

    if (current.isEmpty) {
      currentError = 'Password lama wajib diisi';
    }

    if (newPass.isEmpty) {
      newError = 'Password baru wajib diisi';
    } else if (newPass.length < 8) {
      newError = 'Password baru minimal 8 karakter';
    } else if (newPass == current && current.isNotEmpty) {
      newError = 'Password baru harus berbeda dari password lama';
    }

    if (confirm.isEmpty) {
      confirmError = 'Konfirmasi password wajib diisi';
    } else if (confirm != newPass) {
      confirmError = 'Konfirmasi password harus sama dengan password baru';
    }

    setState(() {
      _currentError = currentError;
      _newError = newError;
      _confirmError = confirmError;
    });

    return currentError == null &&
        newError == null &&
        confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _api.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        confirmPassword: _confirmController.text,
      );

      if (!mounted) return;

      showAppSnack(context, 'Password berhasil diubah');

      setState(() {
        _currentController.clear();
        _newController.clear();
        _confirmController.clear();
        _currentError = null;
        _newError = null;
        _confirmError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      showAppSnack(context, msg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Ubah Password',
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
                    Icons.lock_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ganti password',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan password lama dan password baru untuk memperbarui keamanan akun.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                const FieldLabel('Password Lama'),
                const SizedBox(height: 8),
                TextField(
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Masukkan password lama',
                    hasError: _currentError != null,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                FieldError(message: _currentError),
                const SizedBox(height: 20),
                const FieldLabel('Password Baru'),
                const SizedBox(height: 8),
                TextField(
                  controller: _newController,
                  obscureText: _obscureNew,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
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
                  label: 'Ubah Password',
                  loading: _isLoading,
                  onPressed: _submit,
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
