import 'package:flutter/material.dart';
import 'package:belajar_flutter/pages/profile_page.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        // Profile
        _profileCard(context),

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

        // Logout - visual only
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(
              Icons.logout_rounded,
              size: 19,
            ),
            label: const Text(
              'Log Out',
              style: TextStyle(
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
    );
  }

  // =========================
  // Profile Card
  // =========================

  Widget _profileCard(BuildContext context) {
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
                    'Blog Reader',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'reader@blog.com',
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