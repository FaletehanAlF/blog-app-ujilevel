import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'pages/main_shell.dart';
import 'widgets/app_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: 'assets/.env',
  );

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
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
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
      title: 'NARATA',
      theme: _buildTheme(),
      home: const MainShell(),
    );
  }
}