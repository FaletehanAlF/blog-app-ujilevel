import 'package:flutter/material.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';
import 'category_page.dart';
import 'addproduct.dart';
import 'about_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<String> _titles = [
    'Blog',
    'Articles',
    'Tentang',
    'Settings',
  ];

  final List<Widget> _pages = const [
    HomePage(),
    CategoryPage(),
    AboutPage(),
    SettingsPage(),
  ];

  int get _pageIndex {
    if (_index > 2) {
      return _index - 1;
    }

    return _index;
  }

  Future<void> _openAddArticle() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    );
  }

  void _onTap(int index) {
    if (index == 2) {
      _openAddArticle();
      return;
    }

    setState(() {
      _index = index;
    });
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,

        title: _index == 0
            ? Text(
                'NARATA',
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              )
            : Text(
                _titles[_pageIndex],
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

        centerTitle: true,

        // Icon kiri hanya pada Home
        leading: _index == 0
            ? IconButton(
                onPressed: () {
                  // Fitur notifikasi belum digunakan
                },
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                ),
                tooltip: 'Notifikasi',
              )
            : null,

        // Profile hanya pada Home
        actions: _index == 0
            ? [
                IconButton(
                  onPressed: _openProfile,
                  icon: const Icon(
                    Icons.person_outline_rounded,
                    size: 22,
                  ),
                  tooltip: 'Profile',
                ),
              ]
            : null,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),

      // =========================
      // CONTENT
      // =========================
      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),

      // =========================
      // BOTTOM NAVIGATION
      // =========================
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: Colors.blue.withValues(alpha: 0.15),

          // Warna icon aktif dan tidak aktif
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: Colors.blue,
                );
              }

              return const IconThemeData(
                color: Colors.grey,
              );
            },
          ),

          // Warna tulisan aktif dan tidak aktif
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                );
              }

              return const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              );
            },
          ),
        ),

        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onTap,

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'Articles',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.add_rounded,
                size: 28,
              ),
              label: 'Tambah',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline_rounded),
              selectedIcon: Icon(Icons.info_rounded),
              label: 'Tentang',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}