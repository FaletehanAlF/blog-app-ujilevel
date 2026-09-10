import 'package:flutter/material.dart';
import 'package:belajar_flutter/widgets/app_theme.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

/// Tab Pengaturan — HANYA TAMPILAN, tidak berfungsi.
/// Seluruh baris sengaja tanpa handler (tanpa onTap/onChanged)
/// sehingga tidak ada aksi, tidak ada state, tidak ada bug.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TAMPILAN', style: AppType.sectionLabel),
              const SizedBox(height: 12),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppTheme.mode,
                builder: (context, mode, _) {
                  final dark = mode != ThemeMode.light;
                  return Column(
                    children: [
                      _themeOption(
                        icon: Icons.dark_mode_outlined,
                        title: 'Gelap',
                        subtitle: 'Nyaman untuk malam hari',
                        selected: dark,
                        onTap: () => AppTheme.setDark(true),
                      ),
                      _themeOption(
                        icon: Icons.light_mode_outlined,
                        title: 'Terang',
                        subtitle: 'Jelas untuk siang hari',
                        selected: !dark,
                        onTap: () => AppTheme.setDark(false),
                      ),
                    ],
                  );
                },
              ),
              _row(
                icon: Icons.text_fields_rounded,
                title: 'Ukuran teks',
                subtitle: 'Menyesuaikan keterbacaan artikel',
                trailing: Text(
                  'Sedang',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              Text('UMUM', style: AppType.sectionLabel),
              const SizedBox(height: 12),
              _row(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Kabar artikel terbaru',
                trailing: const Switch(value: false, onChanged: null),
                lastOfSection: false,
              ),
              _row(
                icon: Icons.language_rounded,
                title: 'Bahasa',
                subtitle: 'Bahasa antarmuka aplikasi',
                trailing: Text(
                  'Indonesia',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              _row(
                icon: Icons.folder_outlined,
                title: 'Cache',
                subtitle: 'Data sementara aplikasi',
                trailing: Text(
                  '12 MB',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                last: true,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Hanya pengaturan tema yang berfungsi.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opsi tema Gelap/Terang — SATU-SATUNYA pengaturan yang berfungsi.
  Widget _themeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? AppColors.onAccent
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  size: 22,
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
    required Widget trailing,
    bool last = false,
    bool lastOfSection = true,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: last && lastOfSection ? 0 : 12),
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
