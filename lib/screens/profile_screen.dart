import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:careerwise_sample/services/notification_service.dart';
import 'admin_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await NotificationService.instance.onBeforeLogout();
    } catch (e) {
      debugPrint('Error before logout: $e');
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.popUntil(
      context,
          (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email available';

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _ProfileColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.cardBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            title: Text(
              'My Profile',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
          ),
          body: user == null
              ? _buildErrorState(
            colors,
            'You are not currently signed in.',
            null,
          )
              : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              // Loading State
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return _buildLoadingState(colors);
              }

              // Error State
              if (snapshot.hasError) {
                return _buildErrorState(
                  colors,
                  'Unable to load your profile information.',
                      () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                );
              }

              // Missing Document State
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return _buildErrorState(
                  colors,
                  'Profile information could not be found.',
                      () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                );
              }

              final userData = snapshot.data!.data();

              final firstName =
                  userData?['firstName'] as String? ?? '';

              final lastName =
                  userData?['lastName'] as String? ?? '';

              final fullName = '$firstName $lastName'.trim();

              final displayName = fullName.isNotEmpty
                  ? fullName
                  : (user.displayName?.isNotEmpty == true
                  ? user.displayName!
                  : 'CareerWise User');

              final phone = userData?['phone'] as String? ?? '';

              final role = (userData?['role'] as String? ?? '')
                  .trim();

              final displayRole =
              role.isEmpty ? 'Candidate' : role;

              final formattedRole =
                  '${displayRole[0].toUpperCase()}'
                  '${displayRole.substring(1)}';

              return _buildProfileContent(
                context: context,
                colors: colors,
                isDark: isDark,
                displayName: displayName,
                email: email,
                phone: phone,
                role: formattedRole,
              );
            },
          ),
        );
      },
    );
  }

  // Loading State
  Widget _buildLoadingState(_ProfileColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 18),
          Text(
            'Loading your profile...',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Error State
  Widget _buildErrorState(
      _ProfileColors colors,
      String message,
      VoidCallback? onRetry,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: colors.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: colors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Profile Content
  Widget _buildProfileContent({
    required BuildContext context,
    required _ProfileColors colors,
    required bool isDark,
    required String displayName,
    required String email,
    required String phone,
    required String role,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Profile Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF34D399),
                          Color(0xFF059669),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.cardBg,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 58,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.cardBg,
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // User Name
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 5),

              // User Email
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),

              const SizedBox(height: 10),

              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981)
                      .withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$role Member',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account Information Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black26
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildInfoRow(
                      colors: colors,
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      value: email,
                    ),

                    Divider(
                      height: 28,
                      color: colors.divider,
                    ),

                    if (phone.isNotEmpty) ...[
                      _buildInfoRow(
                        colors: colors,
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        value: phone,
                      ),
                      Divider(
                        height: 28,
                        color: colors.divider,
                      ),
                    ],

                    _buildInfoRow(
                      colors: colors,
                      icon: Icons.verified_user_outlined,
                      title: 'Account Status',
                      value: 'Active',
                      isVerified: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context, colors);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFEF4444)
                          .withValues(alpha: isDark ? 0.40 : 0.30),
                      width: 1.2,
                    ),
                    backgroundColor: const Color(0xFFEF4444)
                        .withValues(alpha: isDark ? 0.12 : 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logout Confirmation Dialog
  void _showLogoutDialog(
      BuildContext context,
      _ProfileColors colors,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colors.cardBorder,
              width: 1.2,
            ),
          ),
          title: Text(
            'Confirm Logout',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to log out of CareerWise?',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Account Information Row
  Widget _buildInfoRow({
    required _ProfileColors colors,
    required IconData icon,
    required String title,
    required String value,
    bool isVerified = false,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Profile Theme Colors
class _ProfileColors {
  final bool isDark;

  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color iconBg;
  final Color divider;

  _ProfileColors({required this.isDark})
      : pageBg = isDark
      ? const Color(0xFF0A140F)
      : const Color(0xFFF0FDF4),
        cardBg = isDark
            ? const Color(0xFF132A1F)
            : Colors.white,
        cardBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        textPrimary = isDark
            ? Colors.white
            : const Color(0xFF0F172A),
        textSecondary = isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
        primary = const Color(0xFF059669),
        iconBg = isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        divider = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.25)
            : const Color(0xFFE2E8F0);
}