import 'package:flutter/material.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: AppColors.onAccent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blog',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Versi 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Aplikasi blog mobile untuk menulis, membaca, dan mengelola artikel dengan kategori serta gambar sampul. Seluruh data artikel dimuat langsung dari REST API.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.65,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // ── Teknologi ──
              Text('TEKNOLOGI', style: AppType.sectionLabel),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.phone_android_outlined,
                title: 'Flutter',
                subtitle: 'Antarmuka aplikasi mobile',
              ),
              _infoRow(
                icon: Icons.cloud_outlined,
                title: 'REST API · Express',
                subtitle: 'Backend data artikel & kategori',
              ),
              _infoRow(
                icon: Icons.storage_outlined,
                title: 'MySQL',
                subtitle: 'Basis data artikel',
              ),
              _infoRow(
                icon: Icons.image_outlined,
                title: 'Upload Gambar',
                subtitle: 'Gambar sampul setiap artikel',
                last: true,
              ),
              const SizedBox(height: 24),
              // ── Fitur ──
              Text('FITUR', style: AppType.sectionLabel),
              const SizedBox(height: 12),
              _infoRow(
                icon: Icons.article_outlined,
                title: 'Kelola Artikel',
                subtitle: 'Lihat, tambah, edit, hapus artikel',
              ),
              _infoRow(
                icon: Icons.grid_view_outlined,
                title: 'Kategori',
                subtitle: 'Jelajahi artikel per topik',
                last: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
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
        ],
      ),
    );
  }
}
