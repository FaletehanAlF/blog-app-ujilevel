import 'dart:async';

import 'package:flutter/material.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/services/socket_service.dart';
import 'package:belajar_flutter/models/notification.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';
import 'articles_page.dart';
import 'addproduct.dart';
import 'about_page.dart';
import 'settings_page.dart';
import 'profile_page.dart';
import 'bookmark_page.dart';
import 'like_page.dart';
import 'notification_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _unreadCount = 0;

  final ApiService _api = ApiService();
  final SocketService _socketService = SocketService();
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey _articlesKey = GlobalKey();

  late final List<Widget> _pages;

  final List<String> _titles = [
    'Home',
    'Articles',
    'About',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homeKey),
      ArticlesPage(key: _articlesKey),
      const AboutPage(),
      const SettingsPage(),
    ];
    _fetchUnreadCount();
    // Realtime: connect sekali, listener dilepas di dispose.
    _socketService.addListener(_onRealtimeNotification);
    unawaited(_socketService.connect());
  }

  int get _pageIndex {
    if (_index > 2) {
      return _index - 1;
    }

    return _index;
  }

  Future<void> _openAddArticle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    );

    // Refresh daftar setelah tambah artikel agar Home/Articles tidak basi.
    // IndexedStack mempertahankan state, jadi panggil fetch secara eksplisit.
    if (result == true) {
      try {
        await _homeKey.currentState?.fetchPosts();
      } catch (_) {}

      try {
        final articlesState = _articlesKey.currentState;
        if (articlesState != null) {
          await (articlesState as dynamic).fetchData();
        }
      } catch (_) {}
    }
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

  void _openBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookmarkPage(),
      ),
    );
  }

  void _openLikes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LikePage(),
      ),
    );
  }

  void _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPage(),
      ),
    );

    if (!mounted) return;

    // Badge bisa berubah selama di NotificationPage, muat ulang sekali.
    _fetchUnreadCount();
  }

  /// Jumlah notifikasi belum dibaca untuk badge bell.
  /// Gagal dimuat bukan error fatal: fallback 0 (badge disembunyikan)
  /// agar Home tetap bisa digunakan tanpa error besar.
  Future<void> _fetchUnreadCount() async {
    try {
      final count = await _api.getUnreadNotificationCount();

      if (!mounted) return;

      setState(() {
        _unreadCount = count;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _unreadCount = 0;
      });
    }
  }

  /// Dipanggil setiap event Socket.IO `notification:new`.
  /// Badge naik secara lokal tanpa reload; nilai absolut tetap
  /// disinkronkan dari server saat kembali dari NotificationPage.
  void _onRealtimeNotification(NotificationModel notification) {
    if (!mounted) return;

    setState(() {
      _unreadCount += 1;
    });

    final message = notification.message.trim();

    if (message.isNotEmpty) {
      showAppSnack(context, message);
    }
  }

  @override
  void dispose() {
    _socketService.removeListener(_onRealtimeNotification);
    _socketService.disconnect();
    super.dispose();
  }

  /// Badge pill kecil untuk jumlah belum dibaca.
  /// 1-99 tampil apa adanya, >99 tampil "99+".
  /// Overlay via Positioned sehingga ukuran icon tetap dan layout
  /// tidak bergeser.
  Widget _buildUnreadBadge(int count) {
    final label = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE5484D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

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
                onPressed: _openNotifications,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: _buildUnreadBadge(_unreadCount),
                      ),
                  ],
                ),
                tooltip: 'Notifikasi',
              )
            : null,

        // Profile hanya pada Home
        actions: _index == 0
            ? [
                IconButton(
                  onPressed: _openLikes,
                  icon: const Icon(
                    Icons.favorite_border_rounded,
                    size: 22,
                  ),
                  tooltip: 'Like',
                ),
                IconButton(
                  onPressed: _openBookmarks,
                  icon: const Icon(
                    Icons.bookmark_border_rounded,
                    size: 22,
                  ),
                  tooltip: 'Bookmark',
                ),
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

      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: Colors.blue.withValues(alpha: 0.15),

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
              label: 'About',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}