import 'package:flutter/material.dart';
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
              const Text('TAMPILAN', style: AppType.sectionLabel),
              const SizedBox(height: 12),
              _row(
                icon: Icons.dark_mode_outlined,
                title: 'Mode gelap',
                subtitle: 'Selalu aktif pada aplikasi ini',
                trailing: const Switch(
                  value: true,
                  onChanged: null,
                ),
              ),
              _row(
                icon: Icons.text_fields_rounded,
                title: 'Ukuran teks',
                subtitle: 'Menyesuaikan keterbacaan artikel',
                trailing: const Text(
                  'Sedang',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('UMUM', style: AppType.sectionLabel),
              const SizedBox(height: 12),
              _row(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                subtitle: 'Kabar artikel terbaru',
                trailing: const Switch(
                  value: false,
                  onChanged: null,
                ),
                lastOfSection: false,
              ),
              _row(
                icon: Icons.language_rounded,
                title: 'Bahasa',
                subtitle: 'Bahasa antarmuka aplikasi',
                trailing: const Text(
                  'Indonesia',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              _row(
                icon: Icons.folder_outlined,
                title: 'Cache',
                subtitle: 'Data sementara aplikasi',
                trailing: const Text(
                  '12 MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                last: true,
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Halaman pengaturan hanya tampilan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
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
              borderRadius:
                  BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon,
                color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
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
