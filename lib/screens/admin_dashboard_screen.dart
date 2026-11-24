import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_profile_screen.dart';

class _AdminColors {
  final bool isDark;

  const _AdminColors({required this.isDark});

  // Background Colors
  Color get pageBg =>
      isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);

  Color get cardBg =>
      isDark ? const Color(0xFF13231B) : Colors.white;

  Color get cardBorder =>
      isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);

  Color get appBarBg =>
      isDark ? const Color(0xFF0E1B15) : Colors.white;

  Color get appBarBorder =>
      isDark ? const Color(0xFF1A3325) : const Color(0xFFE2EFE7);

  // Brand Colors
  Color get primary =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

  Color get primaryAccent =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);

  Color get primaryDark =>
      isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary =>
      isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);

  Color get textSecondary =>
      isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);

  Color get textMuted =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Dividers and Badges
  Color get divider =>
      isDark ? const Color(0xFF1C3426) : const Color(0xFFE5EFE9);

  Color get badgeBg =>
      isDark ? const Color(0x3310B981) : const Color(0x1F059669);

  Color get badgeText =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
}

// =====================================================
// ADMIN DASHBOARD SCREEN
// =====================================================

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  // CHECK ADMIN
  Future<DocumentSnapshot?> _getAdminDocument() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _AdminColors(isDark: isDark);

        return FutureBuilder<DocumentSnapshot?>(
          future: _getAdminDocument(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: colors.pageBg,
                body: Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: colors.pageBg,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error checking admin access:\n\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists) {
              return _accessDeniedScreen(
                'You are not an administrator.',
                colors,
              );
            }

            final data =
            snapshot.data!.data() as Map<String, dynamic>?;

            if (data?['role'] != 'admin') {
              return _accessDeniedScreen(
                'You are not an administrator.',
                colors,
              );
            }

            final adminName =
            data?['name']?.toString().trim().isNotEmpty == true
                ? data!['name'].toString()
                : 'Admin';

            return _buildDashboard(
              context,
              adminName,
              colors,
            );
          },
        );
      },
    );
  }
  // =====================================================
// ACCESS DENIED
// =====================================================

  Widget _accessDeniedScreen(
      String message,
      _AdminColors colors,
      ) {
    return Scaffold(
      backgroundColor: colors.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.cardBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: colors.isDark ? 0.3 : 0.06,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Access Denied',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// MAIN DASHBOARD



// ADMIN PROFILE
  void _showAdminProfile(
      BuildContext context,
      String adminName,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProfileScreen(
          adminName: adminName,
        ),
      ),
    );
  }

  // =====================================================
// MAIN DASHBOARD
// =====================================================

  Widget _buildDashboard(
      BuildContext context,
      String adminName,
      _AdminColors colors,
      ) {
    return Scaffold(
      backgroundColor: colors.pageBg,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: colors.appBarBg,
        surfaceTintColor: colors.appBarBg,
        titleSpacing: 14,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colors.appBarBorder,
            height: 1,
          ),
        ),

        title: LayoutBuilder(
          builder: (context, constraints) {
            final showAdminBadge =
                constraints.maxWidth >= 215;

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors.isDark
                          ? const [
                        Color(0xFF047857),
                        Color(0xFF059669),
                      ]
                          : const [
                        Color(0xFF059669),
                        Color(0xFF10B981),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Flexible(
                  child: Text(
                    'CareerWise',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                if (showAdminBadge) ...[
                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.primary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        color: colors.badgeText,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        actions: [
          // Theme Toggle Button
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 2,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: colors.isDark ? 0.2 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: colors.isDark
                  ? 'Switch to Light Theme'
                  : 'Switch to Dark Theme',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: child.key ==
                        const ValueKey('dark_icon_admin')
                        ? Tween<double>(
                      begin: 0.75,
                      end: 1.0,
                    ).animate(animation)
                        : Tween<double>(
                      begin: 0.25,
                      end: 0.0,
                    ).animate(animation),
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: colors.isDark
                    ? const Icon(
                  Icons.wb_sunny_rounded,
                  key: ValueKey('dark_icon_admin'),
                  color: Color(0xFFFDE047),
                  size: 20,
                )
                    : Icon(
                  Icons.nightlight_round,
                  key: const ValueKey('light_icon_admin'),
                  color: colors.primary,
                  size: 20,
                ),
              ),
              onPressed: () {
                AdminThemeManager.isDarkMode.value =
                !AdminThemeManager.isDarkMode.value;
              },
            ),
          ),

          // Admin Profile Button
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 2,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: colors.isDark ? 0.2 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Admin Profile',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              onPressed: () {
                _showAdminProfile(context, adminName);
              },
              icon: Icon(
                Icons.person_rounded,
                color: colors.primary,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeBanner(
                context,
                adminName,
                colors,
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
  // =====================================================
// WELCOME BANNER
// =====================================================

  Widget _welcomeBanner(
      BuildContext context,
      String adminName,
      _AdminColors colors,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 20 : 24),

          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors.isDark
                  ? const [
                Color(0xFF064E3B),
                Color(0xFF047857),
                Color(0xFF065F46),
              ]
                  : const [
                Color(0xFF065F46),
                Color(0xFF059669),
                Color(0xFF10B981),
              ],
            ),

            borderRadius: BorderRadius.circular(24),

            border: Border.all(
              color: Colors.white.withValues(
                alpha: colors.isDark ? 0.15 : 0.25,
              ),
              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(
                  alpha: colors.isDark ? 0.25 : 0.35,
                ),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Good to see you 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrow ? 26 : 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isNarrow
                          ? 'Manage jobs, applications and career recommendations.'
                          : 'Manage jobs, applications and\ncareer recommendations from here.',
                      maxLines: isNarrow ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.9,
                        ),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: EdgeInsets.all(
                  isNarrow ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.18,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.3,
                    ),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: isNarrow ? 36 : 42,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}