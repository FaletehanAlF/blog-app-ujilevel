import 'package:flutter/material.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

import 'homePage.dart';
import 'category_page.dart';
import 'about_page.dart';
import 'settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final PageController _pageController;
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  static const _titles = ['Blog', 'Kategori', 'Tentang', 'Setting'];
  static const _subtitles = [
    'Cerita yang layak dibaca.',
    'Jelajahi artikel per topik.',
    '',
    'Hanya tampilan.',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (i == _index) return;
    _pageController.jumpToPage(i);
  }

  void _onPageChanged(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: _subtitles[_index].isEmpty ? null : 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _titles[_index],
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (_subtitles[_index].isNotEmpty)
              Text(
                _subtitles[_index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          HomePage(key: _homeKey),
          const CategoryPage(),
          const AboutPage(),
          const SettingsPage(),
        ],
      ),
      // FAB hanya di Beranda — buka Tambah Artikel.
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              onPressed: () => _homeKey.currentState?.openAddArticle(),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              elevation: 0,
              tooltip: 'Tambah artikel',
              child: Icon(Icons.add_rounded, size: 26),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home_rounded, size: 22),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 22),
              activeIcon: Icon(Icons.grid_view_rounded, size: 22),
              label: 'Kategori',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outlined, size: 22),
              activeIcon: Icon(Icons.info_rounded, size: 22),
              label: 'Tentang',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 22),
              activeIcon: Icon(Icons.settings_rounded, size: 22),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
}
