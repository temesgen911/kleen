import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/auth_state_notifier.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bottom_nav_bar.dart';

/// Dark-mode Profile Screen showing user account details, editable profile with photo gallery picker, and sign-out option.
class ProfileScreen extends StatelessWidget {
  final AuthStateNotifier? authNotifier;
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.authNotifier,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildBody(BuildContext context) {
      final user = authNotifier?.currentUser;
      final displayName = user?.effectiveDisplayName ?? 'User';
      final email = user?.email ?? 'user@example.com';
      final firebaseUid = user?.firebaseUid ?? 'uid_local_session';
      final photoUrl = user?.photoUrl;

      return Scaffold(
        backgroundColor: AppColors.backgroundStart,
        bottomNavigationBar: showBottomNav ? const BottomNavBar(activeIndex: 3) : null,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundStart,
                Color(0xFF04060B),
                AppColors.backgroundEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top App Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primaryTeal),
                        onPressed: () => _showEditProfileDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.borderWhite.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar Circle with Photo Gallery Picker trigger
                        GestureDetector(
                          onTap: () => _pickProfileImageFromGallery(context),
                          child: Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryTeal,
                                      AppColors.secondaryPurple,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryTeal.withValues(alpha: 0.35),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildAvatarWidget(photoUrl, displayName),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.backgroundStart, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryTeal.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.photo_camera_rounded, size: 13, color: AppColors.backgroundStart),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Authenticated',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Account Details Section
                  Text(
                    'Account Details',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Account UID',
                    subtitle: firebaseUid.length > 20 ? '${firebaseUid.substring(0, 18)}...' : firebaseUid,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    icon: Icons.cloud_done_outlined,
                    title: 'Database Sync',
                    subtitle: 'Supabase PostgreSQL (Active)',
                    trailingColor: AppColors.primaryTeal,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    icon: Icons.language_rounded,
                    title: 'Timezone',
                    subtitle: user?.timezone ?? 'UTC',
                  ),
                  const SizedBox(height: 32),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.accentCoral.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: AppColors.accentCoral,
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(
                        'Sign Out',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.accentCoral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _confirmSignOut(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (authNotifier != null) {
      return ListenableBuilder(
        listenable: authNotifier!,
        builder: (context, _) => buildBody(context),
      );
    }

    return buildBody(context);
  }

  Widget _buildAvatarWidget(String? photoUrl, String displayName) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(displayName),
        );
      }
      final file = File(photoUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(displayName),
        );
      }
    }
    return _buildFallbackInitial(displayName);
  }

  Widget _buildFallbackInitial(String displayName) {
    return Center(
      child: Text(
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
        style: AppTypography.titleLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? trailingColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderWhite.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: trailingColor ?? AppColors.textPrimary,
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

  Future<void> _pickProfileImageFromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

        if (authNotifier != null) {
          await authNotifier!.updateUserProfile(photoUrl: savedImage.path);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile picture updated from photos! ✨'),
                backgroundColor: AppColors.primaryTeal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[KleenAI Profile] Error picking photo from gallery: $e');
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    if (authNotifier == null) return;
    final nameController = TextEditingController(text: authNotifier?.currentUser?.effectiveDisplayName);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.borderWhite.withValues(alpha: 0.2),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: AppColors.primaryTeal),
              const SizedBox(width: 10),
              Text(
                'Edit Profile',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo Gallery Pick Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  label: const Text(
                    'Choose Photo from Library',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _pickProfileImageFromGallery(context);
                  },
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.borderWhite.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryTeal),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: AppColors.backgroundStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                Navigator.of(ctx).pop();
                if (authNotifier != null && newName.isNotEmpty) {
                  await authNotifier!.updateUserProfile(displayName: newName);
                }
              },
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.borderWhite.withValues(alpha: 0.2),
            ),
          ),
          title: Text(
            'Sign Out',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out of kleenai?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCoral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (authNotifier != null) {
                  await authNotifier!.signOut();
                }
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
