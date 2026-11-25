
// Step 1: Imports and Dependencies


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:careerwise-ai/services/notification_service.dart';
import 'admin_broadcast_screen.dart';
import 'add_job_screen.dart';

// Step 2: Global Admin Theme State Manager (AdminThemeManager)

/// Global manager for Admin Light / Dark theme state
class AdminThemeManager {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  static void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }

  static void setDarkMode(bool value) {
    isDarkMode.value = value;
  }
}

// Step 3: Main Screen Widget Skeleton (AdminProfileScreen)


/// Standalone Full-Screen Admin Profile Screen
/// Beautiful and stylish, designed similar to the user profile with light/dark theme support.
class AdminProfileScreen extends StatelessWidget {
  final String? adminName;

  const AdminProfileScreen({
    super.key,
    this.adminName,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Admin Profile Screen'),
      ),
    );
  }
}

// Step 4: Authentication & Logout Handler
Future<void> _logout(BuildContext context) async {
  try {
    await NotificationService.instance.onBeforeLogout();
  } catch (e) {
    debugPrint('Error before admin logout: $e');
  }

  await FirebaseAuth.instance.signOut();

  if (!context.mounted) return;

  Navigator.popUntil(
    context,
        (route) => route.isFirst,
  );
}

// Step 5: Clipboard Copy Helper with Floating SnackBar
void _copyToClipboard(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text('$label copied to clipboard'),
        ],
      ),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ),
  );
}

// Step 6: Screen Scaffold, Custom AppBar & Theme Reactive Palette
@override
Widget build(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email ?? 'No email available';
  final uid = user?.uid ?? 'Unknown ID';
  final displayName = (adminName?.trim().isNotEmpty == true)
      ? adminName!
      : (user?.displayName?.isNotEmpty == true
      ? user!.displayName!
      : 'CareerWise Admin');

  return ValueListenableBuilder<bool>(
    valueListenable: AdminThemeManager.isDarkMode,
    builder: (context, isDark, _) {
      // Theme color palette (Emerald Green)
      final pageBg = isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
      final cardBg = isDark ? const Color(0xFF13231B) : Colors.white;
      final borderColor = isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
      final textPrimary = isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);
      final textSecondary = isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);
      final primaryColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      final secondaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF047857);
      final iconBoxBg = isDark ? const Color(0x3310B981) : const Color(0x1F059669);
      final iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      final dividerColor = isDark ? const Color(0xFF1C3426) : const Color(0xFFE5EFE9);
      final badgeBg = isDark ? const Color(0x3310B981) : const Color(0x1F059669);
      final badgeText = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);

      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: cardBg,
          surfaceTintColor: cardBg,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Admin Profile',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Step 7: Profile Avatar with Verified Shield Badge
                  _buildAvatarSection(
                    isDark: isDark,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    cardBg: cardBg,
                    iconBoxBg: iconBoxBg,
                    iconColor: iconColor,
                  ),

                  const SizedBox(height: 18),

                  // Step 8: Admin Display Name and Email
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: textSecondary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Step 9: Role and Active Status Badges
                  _buildStatusBadges(
                    badgeBg: badgeBg,
                    badgeText: badgeText,
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),

                  const SizedBox(height: 28),

                  // Step 10 & 11: Account Information Card
                  _buildAccountInfoCard(
                    context: context,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                    iconBoxBg: iconBoxBg,
                    iconColor: iconColor,
                    primaryColor: primaryColor,
                    email: email,
                    uid: uid,
                  ),

                  const SizedBox(height: 20),

                  // Step 12: Administrative Privileges Card
                  _buildPrivilegesCard(
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    dividerColor: dividerColor,
                  ),

                  const SizedBox(height: 25),

                  // Step 13: Logout Button with Confirmation Dialog
                  _buildLogoutButton(
                    context: context,
                    cardBg: cardBg,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

// Step 7: Profile Avatar Stack with Shield / Verified Badge Overlay


Widget _buildAvatarSection({
  required bool isDark,
  required Color primaryColor,
  required Color secondaryColor,
  required Color cardBg,
  required Color iconBoxBg,
  required Color iconColor,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: isDark ? 0.4 : 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3.5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cardBg,
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBoxBg,
            ),
            child: Icon(
              Icons.person,
              size: 65,
              color: iconColor,
            ),
          ),
        ),
      ),

      // Shield / Verified badge overlay
      Positioned(
        bottom: 2,
        right: 2,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981),
            border: Border.all(color: cardBg, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    ],
  );
}

