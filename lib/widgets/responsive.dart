import 'package:flutter/material.dart';

/// Helper responsive NARATA dengan breakpoint tunggal 600 sesuai materi.
/// - < 600 = Mobile
/// - >= 600 = Tablet/Desktop/Web
class Responsive {
  static const double breakpoint = 600;

  /// Cek apakah layar mobile berdasarkan lebar [context].
  /// Menggunakan MediaQuery.sizeOf untuk membaca ukuran layar.
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < breakpoint;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= breakpoint;
  }

  /// Padding horizontal responsive:
  /// - Mobile (<600): 16-20
  /// - Desktop (>=600): 32
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < breakpoint ? 16.0 : 32.0;
  }

  /// Max width konten agar tidak melebar berlebihan di desktop.
  static const double maxContentWidth = 720;
  static const double maxFormWidth = 640;
  static const double maxNarrowWidth = 420;
}

/// Widget pembungkus konten agar tidak melebar berlebihan di desktop.
/// Menggunakan Center + ConstrainedBox sesuai materi Form responsive.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // MediaQuery untuk menyesuaikan padding horizontal
    final hPad = Responsive.horizontalPadding(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(horizontal: hPad),
          child: child,
        ),
      ),
    );
  }
}

/// Padding responsive yang menyesuaikan ukuran layar via MediaQuery.
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double verticalMobile;
  final double verticalDesktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.verticalMobile = 24,
    this.verticalDesktop = 32,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < Responsive.breakpoint ? 16.0 : 32.0;
    final vPad = width < Responsive.breakpoint
        ? verticalMobile
        : verticalDesktop;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 32),
      child: child,
    );
  }
}

/// Grid responsive untuk daftar artikel.
/// Menggunakan LayoutBuilder + breakpoint 600.
/// - Mobile: 1 kolom
/// - Desktop: 2 kolom
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 14,
    this.runSpacing = 14,
    this.childAspectRatio = 1.1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Responsive.breakpoint;
        final crossAxisCount = isMobile ? 1 : 2;
        // Jika hanya 1 kolom, gunakan Column agar height natural
        if (crossAxisCount == 1) {
          return Column(children: children);
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (_, index) => children[index],
        );
      },
    );
  }
}
