import 'package:flutter/material.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

/// Halaman Profil — informasi akun penulis (tampilan).
/// Dibuka dari ikon profil di AppBar. Tanpa bottom navigation.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
        title: const Text('Profil'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Identitas ──
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.textSecondary,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Penulis Blog',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'penulis@blog.app',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('INFORMASI AKUN', style: AppType.sectionLabel),
                const SizedBox(height: 12),
                _row(
                  icon: Icons.badge_outlined,
                  title: 'Nama',
                  subtitle: 'Penulis Blog',
                ),
                _row(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: 'penulis@blog.app',
                ),
                _row(
                  icon: Icons.edit_note_outlined,
                  title: 'Peran',
                  subtitle: 'Penulis & pengelola artikel',
                  last: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    bool last = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: last ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
