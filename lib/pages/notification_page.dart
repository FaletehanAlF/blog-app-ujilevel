import 'dart:async';

import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../services/api.dart';
import '../services/socket_service.dart';
import '../pages/detail_post_screen.dart';
import '../widgets/app_ui.dart';

/// Notifikasi aktivitas pada artikel milik user yang sedang login.
/// Backend menentukan kepemilikan dari JWT. Seluruh data berasal
/// dari `GET /notifications`, tanpa data dummy.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ApiService apiService = ApiService();
  final SocketService _socketService = SocketService();

  List<NotificationModel> notifications = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _socketService.addListener(_onRealtimeNotification);
  }

  @override
  void dispose() {
    _socketService.removeListener(_onRealtimeNotification);
    super.dispose();
  }

  /// Sisipan lokal agar notifikasi realtime langsung terlihat tanpa
  /// menunggu refresh. Dedupe berdasarkan id: item yang sama akan
  /// muncul lagi dari `GET /notifications` saat refresh (yang me-replace
  /// seluruh list), sehingga tidak terjadi duplikat.
  void _onRealtimeNotification(NotificationModel notification) {
    if (!mounted) return;

    if (notification.id != 0 &&
        notifications.any((item) => item.id == notification.id)) {
      return;
    }

    setState(() {
      notifications.insert(0, notification);
    });
  }

  Future<void> fetchNotifications() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await apiService.getNotifications();

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });

      // Daftar sudah tampil; tandai dibaca di background tanpa
      // memengaruhi daftar. Badge disegarkan MainShell saat kembali.
      unawaited(_markAllAsRead());
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Menandai semua notifikasi sebagai dibaca tanpa mengganggu daftar.
  /// Gagal menandai bukan error fatal: tidak ada setState, tidak ada
  /// snackbar, daftar tetap ditampilkan apa adanya.
  Future<void> _markAllAsRead() async {
    try {
      await apiService.markAllNotificationsAsRead();
    } catch (_) {
      // Abaikan: badge akan disegarkan saat kembali ke MainShell.
    }
  }

  Future<void> openDetail(NotificationModel notification) async {
    if (notification.postId <= 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPostScreen(
          postId: notification.postId,
        ),
      ),
    );
  }

  /// Mengubah `created_at` ISO 8601 backend menjadi teks ramah pengguna.
  /// Aman untuk timezone berbeda karena `NotificationModel` sudah
  /// menormalkan ke waktu lokal; di sini tetap ditangani defensif.
  String _formatTime(DateTime createdAt) {
    final local =
        createdAt.isUtc ? createdAt.toLocal() : createdAt;
    final diff = DateTime.now().difference(local);

    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Baru saja';
    }

    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes menit yang lalu';
    }

    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours jam yang lalu';
    }

    if (diff.inDays == 1) {
      return 'Kemarin';
    }

    if (diff.inDays < 30) {
      return '${diff.inDays} hari yang lalu';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          tooltip: 'Kembali',
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: RefreshIndicator(
        backgroundColor: AppColors.surface2,
        color: Colors.blue,
        onRefresh: fetchNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoading();
    }

    if (errorMessage != null) {
      return _buildError();
    }

    if (notifications.isEmpty) {
      return _buildEmpty();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('Notifikasi', style: AppType.pageTitle),
        const SizedBox(height: 6),
        Text(
          'Aktivitas terbaru pada artikel Anda.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ...notifications.map(_buildNotificationItem),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final isLike = notification.type.toLowerCase() == 'like';
    final actorName = notification.actorName.trim().isEmpty
        ? 'Seseorang'
        : notification.actorName;
    final message = notification.message.trim().isEmpty
        ? 'Ada aktivitas baru pada artikel Anda.'
        : notification.message;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => openDetail(notification),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 6,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            isLike
                ? Icons.favorite_rounded
                : Icons.notifications_rounded,
            color: isLike
                ? const Color(0xFFE5484D)
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          actorName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 2),
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: notification.postId > 0
            ? Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 21,
              )
            : null,
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Container(
          width: 150,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 270,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 24),
        const LoadingSkeletonList(),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ErrorStateView(
            message:
                'Notifikasi gagal dimuat.${errorMessage != null && errorMessage!.isNotEmpty ? ' $errorMessage' : ''}',
            onRetry: fetchNotifications,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textMuted,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Notifikasi aktivitas pada artikel Anda akan muncul di sini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
