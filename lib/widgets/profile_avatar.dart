import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/api.dart';
import 'app_ui.dart';

/// Menggabungkan path `profile_image` backend (mis. "/uploads/abc.jpg")
/// dengan base URL backend. Mengembalikan null jika tidak ada foto.
/// URL absolut dipakai apa adanya. URL mentah tidak pernah ditampilkan
/// ke user; helper ini hanya untuk pemuatan gambar.
String? profileImageUrl(String? path) {
  if (path == null || path.trim().isEmpty) {
    return null;
  }

  final trimmed = path.trim();

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  return '${ApiService.baseUrl}$trimmed';
}

/// Avatar lingkaran untuk foto profil, mengikuti desain NARATA.
/// Tanpa foto: ikon person di atas surface. Dengan foto: network image
/// dengan placeholder dan fallback ikon saat gagal dimuat.
class ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final double size;

  const ProfileAvatar({
    super.key,
    this.imagePath,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final url = profileImageUrl(imagePath);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
              size: size * 0.5,
            )
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.surface2,
                alignment: Alignment.center,
                child: SizedBox(
                  width: size * 0.35,
                  height: size * 0.35,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.person_outline_rounded,
                color: AppColors.textSecondary,
                size: size * 0.5,
              ),
            ),
    );
  }
}
