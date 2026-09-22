import 'package:flutter/material.dart';
import 'package:belajar_flutter/pages/change_password_page.dart';
import 'package:belajar_flutter/pages/profile_page.dart';
import 'package:belajar_flutter/pages/statistics_page.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/services/socket_service.dart';
import 'package:belajar_flutter/pages/login_page.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _api = ApiService();
  String? _email;
  String? _role;
  String? _name;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await _api.init();
    final email = await _api.getEmail();
    final role = await _api.getRole();
    final name = await _api.getUserName();
    if (!mounted) return;
    setState(() {
      _email = email;
      _role = role;
      _name = name;
    });
  }

  Future<void> _doLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
        title: Text('Keluar akun?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Sesi login akan dihapus dan kamu perlu login kembali.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loggingOut = true);
    // Putus socket realtime sebelum token dihapus.
    SocketService().disconnect();
    await _api.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.sizeOf(context).width < 600 ? 18.0 : 32.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 30),
      children: [
        // Profile
        _profileCard(context),

        const SizedBox(height: 12),

        // Statistik - dashboard ringkasan pengguna
        _settingsSection(
          children: [
            _settingItemTappable(
              icon: Icons.bar_chart_rounded,
              title: 'Statistik',
              subtitle: 'Ringkasan artikel, views, likes & bookmark',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatisticsPage(),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Akun
        _settingsSection(
          children: [
            _settingItemTappable(
              icon: Icons.lock_outline_rounded,
              title: 'Ubah Password',
              subtitle: 'Ganti password akun kamu',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordPage(),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 12),

        // General settings
        _settingsSection(
          children: [
            _settingItem(
              icon: Icons.notifications_none_rounded,
              title: 'Pause notifications',
              trailing: _fakeSwitch(),
            ),
            _settingItem(
              icon: Icons.tune_rounded,
              title: 'General settings',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 21,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Preferences
        _settingsSection(
          children: [
            _settingItem(
              icon: Icons.dark_mode_outlined,
              title: 'Dark mode',
              trailing: _fakeSwitch(),
            ),
            _settingItem(
              icon: Icons.translate_rounded,
              title: 'Language',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 21,
              ),
            ),
            _settingItem(
              icon: Icons.people_outline_rounded,
              title: 'My Contact',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 21,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Information
        _settingsSection(
          children: [
            _settingItem(
              icon: Icons.help_outline_rounded,
              title: 'FAQ',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 21,
              ),
            ),
            _settingItem(
              icon: Icons.info_outline_rounded,
              title: 'Terms of service',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 21,
              ),
            ),
            _settingItem(
              icon: Icons.policy_outlined,
              title: 'User policy',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 21,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Logout - sekarang aktif
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _loggingOut ? null : _doLogout,
            icon: _loggingOut
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textMuted,
                    ),
                  )
                : const Icon(
                    Icons.logout_rounded,
                    size: 19,
                  ),
            label: Text(
              _loggingOut ? 'Keluar...' : 'Log Out',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white,
              disabledForegroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

            Center(
              child: Text(
                'Blog Application • 2026',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Profile Card
  // =========================

  Widget _profileCard(BuildContext context) {
    final displayName = _name != null && _name!.isNotEmpty
        ? _name!
        : 'Blog Reader';
    final displayEmail = _email != null && _email!.isNotEmpty
        ? _email!
        : 'reader@blog.com';
    final displayRole = _role != null && _role!.isNotEmpty ? _role! : 'user';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.textPrimary,
                size: 27,
              ),
            ),

            const SizedBox(width: 13),

            // User information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$displayEmail • $displayRole',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Settings Section
  // =========================

  Widget _settingsSection({
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // =========================
  // Setting Item
  // =========================

  Widget _settingItem({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          trailing,
        ],
      ),
    );
  }

  Widget _settingItemTappable({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Fake Switch
  // =========================

  Widget _fakeSwitch() {
    return Container(
      width: 45,
      height: 27,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerLeft,
      child: Container(
        width: 21,
        height: 21,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
