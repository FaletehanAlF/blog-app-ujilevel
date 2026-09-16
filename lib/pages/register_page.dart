import 'package:flutter/material.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final ApiService apiService = ApiService();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscure = true;

  String? nameError;
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool validate() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
      nameError = name.isEmpty
          ? 'Nama wajib diisi'
          : name.length < 3
              ? 'Nama minimal 3 karakter'
              : null;

      emailError = email.isEmpty
          ? 'Email wajib diisi'
          : !email.contains('@')
              ? 'Format email tidak valid'
              : null;

      passwordError = password.isEmpty
          ? 'Password wajib diisi'
          : password.length < 6
              ? 'Password minimal 6 karakter'
              : null;
    });

    return nameError == null && emailError == null && passwordError == null;
  }

  Future<void> doRegister() async {
    if (!validate()) return;

    setState(() => isLoading = true);

    try {
      await apiService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      showAppSnack(context, 'Registrasi berhasil, silakan login');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
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
          onPressed: isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 21),
        ),
        title: const Text(
          'Daftar Akun',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                Text(
                  'Buat akun baru',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Daftar untuk mulai menulis dan mengelola artikel.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                const FieldLabel('Nama'),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Nama lengkap',
                    hasError: nameError != null,
                  ),
                ),
                FieldError(message: nameError),

                const SizedBox(height: 20),

                const FieldLabel('Email'),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'contoh@email.com',
                    hasError: emailError != null,
                  ),
                ),
                FieldError(message: emailError),

                const SizedBox(height: 20),

                const FieldLabel('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  cursorColor: AppColors.accent,
                  decoration: appInputDecoration(
                    hint: 'Minimal 6 karakter',
                    hasError: passwordError != null,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => doRegister(),
                ),
                FieldError(message: passwordError),

                const SizedBox(height: 28),

                primaryButton(
                  label: 'Daftar',
                  loading: isLoading,
                  onPressed: doRegister,
                ),

                const SizedBox(height: 16),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun?',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: const Text('Masuk'),
                      ),
                    ],
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
