import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────
/// DARK MODERN EDITORIAL BLOG — design system tunggal.
/// Hierarki: typography → whitespace → image → layout.
/// Satu aksen (paper white) + satu warna destruktif (red).
/// Tanpa gradient, tanpa glassmorphism, tanpa shadow berat.
/// ─────────────────────────────────────────────────────────────
class AppColors {
  static bool get _dark => AppTheme.isDark;

  static Color get background =>
      _dark ? const Color(0xFF0B0B0B) : const Color(0xFFF7F8FA);
  static Color get surface => _dark ? const Color(0xFF141414) : Colors.white;
  static Color get surface2 =>
      _dark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F4F6);
  static Color get border =>
      _dark ? const Color(0xFF292929) : const Color(0xFFE5E7EB);

  static Color get textPrimary =>
      _dark ? const Color(0xFFF5F5F5) : const Color(0xFF111827);
  static Color get textSecondary =>
      _dark ? const Color(0xFFA3A3A3) : const Color(0xFF6B7280);
  static Color get textMuted =>
      _dark ? const Color(0xFF737373) : const Color(0xFF9CA3AF);

  /// Satu-satunya aksen: paper white di mode gelap,
  /// slate-900 di mode terang. Dipakai untuk primary
  /// action / active / link / focus saja.
  static Color get accent =>
      _dark ? const Color(0xFFF5F5F5) : const Color(0xFF111827);
  static Color get onAccent => _dark ? const Color(0xFF0B0B0B) : Colors.white;

  static Color get danger => const Color(0xFFE5484D);
  static Color get dangerSoft =>
      _dark ? const Color(0xFF241719) : const Color(0xFFFEF2F2);
  static Color get dangerBorder =>
      _dark ? const Color(0xFF4A2526) : const Color(0xFFF3C2C2);

  static Color get skeleton =>
      _dark ? const Color(0xFF1C1C1C) : const Color(0xFFEEF0F3);
  static Color get skeletonHi =>
      _dark ? const Color(0xFF262626) : const Color(0xFFE2E5EA);
}

/// Spacing: hanya 8 · 12 · 16 · 20 · 24 · 32.
class AppSpace {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Radius konsisten: kecil 8 · input/button 12 · card/image 16.
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

class AppType {
  static TextStyle get pageTitle => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );
  static TextStyle get cardTitle => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 17,
    height: 1.4,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static TextStyle get detailTitle => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 26,
    height: 1.25,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  );
  static TextStyle get body => TextStyle(
    color: AppTheme.isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151),
    fontSize: 15,
    height: 1.75,
  );
  static TextStyle get excerpt =>
      TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6);
  static TextStyle get category => TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );
  static TextStyle get sectionLabel => TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
  );
  static TextStyle get hint =>
      TextStyle(color: AppColors.textMuted, fontSize: 14);
}

/// Kategori: kecil & subtle, tidak mendominasi.
class CategoryLabel extends StatelessWidget {
  final String label;
  const CategoryLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppType.category,
    );
  }
}

/// Label form: jelas, satu gaya di Add & Edit.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  const FieldLabel(this.text, {super.key, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 8),
            Text(
              'Opsional',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error validasi inline tepat di bawah field.
class FieldError extends StatelessWidget {
  final String? message;
  const FieldError({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Input dark: surface + border subtle, focus memakai aksen.
InputDecoration appInputDecoration({
  required String hint,
  bool hasError = false,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: AppType.hint,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffixIcon,
    suffixIconColor: AppColors.textMuted,
    prefixIconColor: AppColors.textMuted,
    enabledBorder: border(hasError ? AppColors.danger : AppColors.border),
    focusedBorder: border(hasError ? AppColors.danger : AppColors.accent),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger),
  );
}

void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface2,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: AppColors.border),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.danger : AppColors.accent,
              size: 19,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Dialog konfirmasi hapus — dark, clean, eksplisit.
Future<bool> showDeleteDialog(BuildContext context, {required String title}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hapus artikel?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '“$title” akan dihapus permanen dan tidak bisa dikembalikan.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).then((v) => v ?? false);
}

/// Tombol primary editorial: aksen paper, tinggi konsisten 50.
Widget primaryButton({
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
  IconData? icon,
}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        disabledBackgroundColor: AppColors.surface2,
        disabledForegroundColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textMuted,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    ),
  );
}

/// Skeleton loading editorial — blok netral, tanpa animasi berlebihan.
class LoadingSkeletonList extends StatelessWidget {
  const LoadingSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.skeleton,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(width: 90, height: 12),
                  const SizedBox(height: 12),
                  _bar(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  _bar(width: 200, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeletonHi,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.article_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.dangerBorder),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                color: AppColors.danger,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Coba lagi',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
