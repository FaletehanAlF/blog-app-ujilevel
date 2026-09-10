import 'package:flutter/material.dart';

import 'package:belajar_flutter/widgets/app_ui.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tentang NARATA',
                style: AppType.pageTitle,
              ),
              const SizedBox(height: 8),
              Text(
                'Aplikasi blog sederhana untuk membaca dan mengelola artikel.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.onAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NARATA',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Blog Mobile · Versi 1.0.0',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'NARATA membantu pengguna membaca, menulis, dan mengelola artikel berdasarkan kategori. Data aplikasi terhubung dengan REST API dan database.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'TEKNOLOGI',
                style: AppType.sectionLabel,
              ),
              const SizedBox(height: 12),

              _infoRow(
                Icons.phone_android_outlined,
                'Flutter',
                'Framework aplikasi mobile',
              ),
              _infoRow(
                Icons.cloud_outlined,
                'Node.js + Express.js',
                'Backend dan REST API',
              ),
              _infoRow(
                Icons.storage_outlined,
                'MySQL',
                'Penyimpanan data artikel dan kategori',
                last: true,
              ),

              const SizedBox(height: 28),

              Text(
                'FITUR UTAMA',
                style: AppType.sectionLabel,
              ),
              const SizedBox(height: 12),

              _infoRow(
                Icons.article_outlined,
                'Kelola Artikel',
                'Tambah, lihat, edit, dan hapus artikel',
              ),
              _infoRow(
                Icons.category_outlined,
                'Kategori',
                'Menjelajahi artikel berdasarkan topik',
              ),
              _infoRow(
                Icons.image_outlined,
                'Gambar Sampul',
                'Menambahkan gambar pada artikel',
                last: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String subtitle, {
    bool last = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: last ? 0 : 10),
      padding: const EdgeInsets.all(15),
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
            child: Icon(
              icon,
              color: AppColors.textSecondary,
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
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