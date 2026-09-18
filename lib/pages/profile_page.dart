import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/post.dart';
import 'package:belajar_flutter/services/api.dart';
import 'package:belajar_flutter/widgets/app_ui.dart';
import 'package:belajar_flutter/widgets/profile_avatar.dart';
import 'package:image_picker/image_picker.dart';

import 'detail_post_screen.dart';
import 'statistics_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _api = ApiService();
  String _name = 'Narata User';
  String _email = 'reader@blog.com';
  String _role = 'Pembaca';
  String? _profileImage;
  int? _userId;
  int? _articleCount;
  List<Post> _myPosts = [];
  bool _loadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await _api.init();
    int? userId = await _api.getUserId();

    String? name = await _api.getUserName();
    String? email = await _api.getEmail();
    String? role = await _api.getRole();
    String? profileImage;
    int? articleCount;

    // Data profil segar dari server, fallback ke cache lokal jika gagal.
    try {
      final me = await _api.getMe();

      name = me['name']?.toString() ?? name;
      email = me['email']?.toString() ?? email;
      role = me['role']?.toString() ?? role;
      articleCount = int.tryParse(
        me['article_count']?.toString() ?? '',
      );

      final serverImage = me['profile_image']?.toString();

      if (serverImage != null && serverImage.isNotEmpty) {
        profileImage = serverImage;
      }

      // Sinkronkan userId dari server agar filter "Artikel Saya"
      // tetap benar walau cache lokal belum menyimpan id.
      final serverId = int.tryParse(
        me['id']?.toString() ?? '',
      );
      if (serverId != null) {
        userId = serverId;
      }
    } catch (_) {
      // Abaikan, gunakan data tersimpan lokal.
    }

    if (!mounted) return;

    setState(() {
      _userId = userId;
      if (name != null && name.isNotEmpty) _name = name;
      if (email != null && email.isNotEmpty) _email = email;
      if (role != null && role.isNotEmpty) {
        // Tampilkan role apa adanya, misal admin / user
        _role = role;
      }
      _profileImage = profileImage;
      _articleCount = articleCount;
    });

    await _loadMyPosts();
  }

  /// Hanya artikel dengan posts.user_id == ID user yang sedang login.
  Future<void> _loadMyPosts() async {
    if (!mounted) return;

    setState(() {
      _loadingPosts = true;
      _postsError = null;
    });

    try {
      final posts = await _api.getPosts();

      if (!mounted) return;

      final mine = posts
          .where((post) => post.userId != null && post.userId == _userId)
          .toList();

      setState(() {
        _myPosts = mine;
        _articleCount ??= mine.length;
        _loadingPosts = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingPosts = false;
        _postsError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Dialog edit profil: ubah nama dan/atau foto dari gallery.
  /// Foto bersifat opsional; nama saja tetap bisa disimpan.
  Future<void> _showEditDialog() async {
    final nameController = TextEditingController(text: _name);
    final picker = ImagePicker();

    XFile? selectedImage;
    Uint8List? previewBytes;
    String? errorText;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickPhoto() async {
            final image = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );

            if (image == null) return;

            final bytes = await image.readAsBytes();

            setDialogState(() {
              selectedImage = image;
              previewBytes = bytes;
            });
          }

          Future<void> save() async {
            final newName = nameController.text.trim();

            if (newName.isEmpty) {
              setDialogState(() {
                errorText = 'Nama tidak boleh kosong.';
              });
              return;
            }

            setDialogState(() {
              saving = true;
              errorText = null;
            });

            try {
              await _api.updateProfile(
                name: newName,
                profileImage: selectedImage,
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            } catch (error) {
              setDialogState(() {
                saving = false;
                errorText =
                    error.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border),
            ),
            title: Text(
              'Edit Profil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (previewBytes != null)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(
                        previewBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    ProfileAvatar(
                      imagePath: _profileImage,
                      size: 72,
                    ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: saving ? null : pickPhoto,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 17,
                    ),
                    label: Text(
                      selectedImage == null
                          ? 'Ganti Foto'
                          : selectedImage!.name,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    enabled: !saving,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: appInputDecoration(hint: 'Nama'),
                  ),
                  FieldError(message: errorText),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              FilledButton(
                onPressed: saving ? null : save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                ),
                child: saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();

    if (saved == true && mounted) {
      await _loadUser();

      if (!mounted) return;

      showAppSnack(context, 'Profil berhasil diperbarui.');
    }
  }

  Future<void> _openDetail(Post post) async {    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPostScreen(postId: post.id),
      ),
    );

    if (mounted) _loadMyPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                ProfileAvatar(
                  imagePath: _profileImage,
                  size: 88,
                ),
                const SizedBox(height: 16),
                Text(
                  _name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _role,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _showEditDialog,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label: const Text('Edit Profil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Account information
          Text(
            'INFORMASI',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          _infoItem(
            icon: Icons.person_outline_rounded,
            title: 'Nama',
            value: _name,
          ),

          _infoItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: _email,
          ),

          _infoItem(
            icon: Icons.article_outlined,
            title: 'Peran',
            value: _role,
          ),

          _infoItem(
            icon: Icons.numbers_outlined,
            title: 'Jumlah Artikel Saya',
            value: _articleCount?.toString() ?? '-',
          ),

          const SizedBox(height: 10),

          _menuItem(
            icon: Icons.bar_chart_rounded,
            title: 'Statistik',
            subtitle: 'Ringkasan artikel, views, likes & bookmark',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatisticsPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Artikel milik user yang sedang login
          Text(
            'ARTIKEL SAYA',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          _buildMyArticles(),

          const SizedBox(height: 28),

          // Application information
          Text(
            'APLIKASI',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          _menuItem(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Blog',
            subtitle: 'Informasi mengenai aplikasi',
            onTap: () {
              Navigator.pop(context);
            },
          ),

          _menuItem(
            icon: Icons.settings_outlined,
            title: 'Pengaturan',
            subtitle: 'Atur preferensi aplikasi',
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyArticles() {
    if (_loadingPosts) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_postsError != null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Gagal memuat artikel: $_postsError',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadMyPosts,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (_myPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          vertical: 28,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              color: AppColors.textMuted,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada artikel',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Artikel yang kamu buat akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _myPosts.map((post) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            onTap: () => _openDetail(post),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.article_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            title: Text(
              post.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
             subtitle: Row(
               children: [
                 Expanded(
                   child: Text(
                     post.category.isNotEmpty ? post.category : 'Tanpa kategori',
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                     style: TextStyle(
                       color: AppColors.textSecondary,
                       fontSize: 12,
                     ),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(
                       Icons.favorite_border_rounded,
                       color: post.likeCount > 0
                           ? const Color(0xFFE5484D)
                           : AppColors.textMuted,
                       size: 12,
                     ),
                     const SizedBox(width: 2),
                     Text(
                       post.likeCount.toString(),
                       style: TextStyle(
                         color: post.likeCount > 0
                             ? const Color(0xFFE5484D)
                             : AppColors.textMuted,
                         fontSize: 12,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ],
                 ),
               ],
             ),
             trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 21,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
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

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
          size: 21,
        ),
      ),
    );
  }
}
