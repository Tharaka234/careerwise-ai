import 'package:flutter/material.dart';


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

  @override
  Widget build(BuildContext context) {
    final colors = _AdminColors(
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

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
                  'Admin Dashboard',
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