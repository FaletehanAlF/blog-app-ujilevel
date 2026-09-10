import 'package:flutter/material.dart';
import 'pages/main_shell.dart';
import 'widgets/app_theme.dart';
import 'widgets/app_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.load();
  runApp(const BlogApp());
}

ThemeData _buildTheme({required bool dark}) {
  final scheme = dark
      ? const ColorScheme.dark(
          primary: Color(0xFFF5F5F5),
          onPrimary: Color(0xFF0B0B0B),
          surface: Color(0xFF0B0B0B),
          error: Color(0xFFE5484D),
        )
      : const ColorScheme.light(
          primary: Color(0xFF111827),
          onPrimary: Colors.white,
          surface: Colors.white,
          error: Color(0xFFDC2626),
        );
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF0B0B0B) : const Color(0xFFF7F8FA),
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor:
          dark ? const Color(0xFF0B0B0B) : Colors.white,
      foregroundColor: dark
          ? const Color(0xFFF5F5F5)
          : const Color(0xFF111827),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: dark
            ? const Color(0xFFF5F5F5)
            : const Color(0xFF111827),
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Blog App',
          theme: _buildTheme(dark: false),
          darkTheme: _buildTheme(dark: true),
          themeMode: mode,
          home: const MainShell(),
        );
      },
    );
  }
}
