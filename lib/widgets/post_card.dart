import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/post.dart';
import '../services/api.dart';
import '../pages/public_profile_page.dart';
import 'app_ui.dart';
import 'profile_avatar.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onDelete,
    required this.onTap,
  });

  String get _imageUrl => (post.image != null && post.image!.isNotEmpty)
      ? '${ApiService.baseUrl}${post.image}'
      : '';

  @override
  Widget build(BuildContext context) {
    // MediaQuery untuk padding proporsional
    final screenWidth = MediaQuery.sizeOf(context).width;
    final innerPadding = screenWidth < 600 ? 16.0 : 20.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashColor: Colors.white.withValues(alpha: 0.04),
          highlightColor: Colors.white.withValues(alpha: 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                  child: _imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.surface2,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              // ── CATEGORY → TITLE → EXCERPT ──
              Padding(
                padding: EdgeInsets.all(innerPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryLabel(label: post.category),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.excerpt,
                    ),
                    const SizedBox(height: 12),
                    _buildAuthor(context),
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Flexible untuk teks agar tidak overflow pada layar sempit
                        Flexible(
                          child: Text(
                            'Baca artikel',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Baris author: foto profil + nama. Ketuk untuk membuka profil
  /// publik author. Tidak tampil jika tidak ada info author.
  Widget _buildAuthor(BuildContext context) {
    final authorId = post.author?.id ?? post.userId;
    final name = post.authorName;

    if ((authorId == null || authorId <= 0) &&
        (name == null || name.isEmpty)) {
      return const SizedBox.shrink();
    }

    final canOpenProfile = authorId != null && authorId > 0;

    return GestureDetector(
      onTap: canOpenProfile
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicProfilePage(userId: authorId),
                ),
              );
            }
          : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          ProfileAvatar(
            imagePath: post.authorProfileImage,
            size: 26,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (name == null || name.isEmpty)
                  ? 'Penulis tidak diketahui'
                  : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canOpenProfile)
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.surface2,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 30),
    );
  }
}
