import 'package:flutter/material.dart';
import 'package:belajar_flutter/pages/email_verification_page.dart';
import 'package:belajar_flutter/pages/forgot_password_page.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:belajar_flutter/pages/register_page.dart';
import 'package:belajar_flutter/pages/main_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiService apiService = ApiService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscure = true;

  // State khusus email belum terverifikasi (HTTP 403 dari POST /auth/login).
  // Dipisah dari error login lain agar tahap berikutnya mudah melanjutkan
  // (mis. navigasi ke halaman verifikasi / resend verification).
  // Halaman verifikasi email belum ada pada tahap ini, jadi state ini
  // disiapkan dulu tanpa membuat halaman baru.
  bool isEmailUnverified = false;
  String? unverifiedEmail;

  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool validate() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    setState(() {
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

    return emailError == null && passwordError == null;
  }

  Future<void> doLogin() async {
    if (!validate()) return;

    setState(() {
      isLoading = true;
      // Reset penanda 403 setiap percobaan login baru.
      isEmailUnverified = false;
      unverifiedEmail = null;
    });

    try {
      await apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      // HTTP 200: behavior dipertahankan — token sudah disimpan di
      // ApiService.login, lanjut ke halaman utama dan hapus stack login.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
      showAppSnack(context, 'Login berhasil');
    } on EmailNotVerifiedException catch (e) {
      // HTTP 403 dari POST /auth/login: email belum diverifikasi.
      // Bukan error server biasa — tampilkan pesan khusus verifikasi.
      // Halaman verifikasi email belum ada, jadi belum ada navigasi;
      // state disiapkan agar mudah dilanjutkan (lihat goToEmailVerification).
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isEmailUnverified = true;
        unverifiedEmail = e.email;
      });
      showAppSnack(context, e.message, isError: true);
      // TODO(stage-2): panggil goToEmailVerification(e.email) setelah halaman
      // verifikasi email tersedia. Routing existing memakai Navigator.push
      // imperatif (tanpa named route), jadi tinggal isi method tersebut.
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      showAppSnack(context, msg, isError: true);
    }
  }

  // TAHAP BERIKUTNYA: hook navigasi ke halaman verifikasi email.
  //
  // Halaman tersebut BELUM ADA pada tahap ini (scope: hanya handle 403 di
  // login), jadi method ini sengaja belum melakukan Navigator.push agar tidak
  // membuat halaman baru. Saat halaman verifikasi sudah dibuat, cukup isi
  // body method ini, contoh:
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => VerifyEmailPage(email: email)),
  //   );
  // dan panggil goToEmailVerification(unverifiedEmail) dari branch 403 di atas.
  // Parameter [email] sudah tersedia dari EmailNotVerifiedException untuk
  // keperluan POST /auth/resend-verification pada tahap berikutnya.
  void goToEmailVerification(String email) {
    // TODO(stage-2): arahkan ke halaman verifikasi email dengan membawa email.
  }

  void goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
            40,
            MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
            40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Judul
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          Icons.article_outlined,
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'RuangKata',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Masuk untuk melanjutkan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Login',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan email dan password yang terdaftar.',
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
                  onSubmitted: (_) => doLogin(),
                ),
                FieldError(message: passwordError),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ? null : goToForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                primaryButton(
                  label: 'Masuk',
                  loading: isLoading,
                  onPressed: doLogin,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : goToRegister,
                      child: const Text('Daftar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
