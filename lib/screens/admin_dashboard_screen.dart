import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    final colors = _AdminColors(
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    return FutureBuilder<DocumentSnapshot?>(
      future: _getAdminDocument(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
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

        return _buildDashboard(context, adminName, colors);
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

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: colors.appBarBg,
        surfaceTintColor: colors.appBarBg,
        title: Text(
          'CareerWise Admin',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.cardBorder,
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 60,
                  color: colors.primary,
                ),

                const SizedBox(height: 20),

                Text(
                  'Welcome, $adminName',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Manage jobs, applications and career recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}