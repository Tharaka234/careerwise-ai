
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

// Step 8 & 9: Role and Active Account Status Badges


Widget _buildStatusBadges({
  required Color badgeBg,
  required Color badgeText,
  required bool isDark,
  required Color primaryColor,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_rounded,
              size: 14,
              color: badgeText,
            ),
            const SizedBox(width: 6),
            Text(
              'ADMINISTRATOR',
              style: TextStyle(
                color: badgeText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Active',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Step 10 & 11: Account Information Card Builder
Widget _buildAccountInfoCard({
  required BuildContext context,
  required bool isDark,
  required Color cardBg,
  required Color borderColor,
  required Color textPrimary,
  required Color textSecondary,
  required Color dividerColor,
  required Color iconBoxBg,
  required Color iconColor,
  required Color primaryColor,
  required String email,
  required String uid,
}) {
  return Card(
    elevation: isDark ? 4 : 3,
    color: cardBg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: borderColor),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Account Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Email Row
          _buildInfoRow(
            icon: Icons.email_outlined,
            title: 'Admin Email',
            value: email,
            iconBg: iconBoxBg,
            iconColor: iconColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderColor: borderColor,
            trailing: IconButton(
              icon: Icon(Icons.copy_rounded, size: 18, color: textSecondary),
              tooltip: 'Copy Email',
              onPressed: () => _copyToClipboard(context, email, 'Email'),
            ),
          ),
          Divider(height: 30, color: dividerColor),
          // Role Row
          _buildInfoRow(
            icon: Icons.security_outlined,
            title: 'System Role',
            value: 'Administrator',
            iconBg: iconBoxBg,
            iconColor: iconColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderColor: borderColor,
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Full Access',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Divider(height: 30, color: dividerColor),
          // UID Row
          _buildInfoRow(
            icon: Icons.badge_outlined,
            title: 'Admin ID',
            value: uid,
            iconBg: iconBoxBg,
            iconColor: iconColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderColor: borderColor,
            isMono: true,
            trailing: IconButton(
              icon: Icon(Icons.copy_rounded, size: 18, color: textSecondary),
              tooltip: 'Copy Admin ID',
              onPressed: () => _copyToClipboard(context, uid, 'Admin ID'),
            ),
          ),
          Divider(height: 30, color: dividerColor),
          // Status Row
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            title: 'Account Status',
            value: 'Active & Verified',
            iconBg: iconBoxBg,
            iconColor: const Color(0xFF10B981),
            textPrimary: const Color(0xFF10B981),
            textSecondary: textSecondary,
            borderColor: borderColor,
          ),
        ],
      ),
    ),
  );

  // Step 12: Administrative Privileges Card Builder


  Widget _buildPrivilegesCard({
  required bool isDark,
  required Color cardBg,
  required Color borderColor,
  required Color textPrimary,
  required Color textSecondary,
  required Color dividerColor,
  }) {
    return Card(
      elevation: isDark ? 4 : 3,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Administrative Privileges',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildPrivilegeRow(
              icon: Icons.work_outline_rounded,
              title: 'Job Management',
              description: 'Create, update, and manage job vacancies',
              color: const Color(0xFF3B82F6),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),
            Divider(height: 24, color: dividerColor),
            _buildPrivilegeRow(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Application Review',
              description: 'Review applicants and update candidate status',
              color: const Color(0xFF10B981),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),
            Divider(height: 24, color: dividerColor),
            _buildPrivilegeRow(
              icon: Icons.campaign_outlined,
              title: 'Broadcast Alerts',
              description: 'Send push notifications to all users',
              color: const Color(0xFF8B5CF6),
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  // Step 13: Logout Button with Confirmation Dialog


  Widget _buildLogoutButton({
    required BuildContext context,
    required Color cardBg,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(
            color: Colors.redAccent.withValues(alpha: 0.5),
          ),
          backgroundColor: Colors.redAccent.withValues(alpha: isDark ? 0.08 : 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'Are you sure you want to logout from admin account?',
                  style: TextStyle(color: textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _logout(context);
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          );
        },
        icon: const Icon(
          Icons.logout,
        ),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Step 14: Reusable Info Row & Privilege Row Builder Widgets


  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconBg,
    required Color iconColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    bool isMono = false,
    Widget? badge,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
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
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                        fontFamily: isMono ? 'monospace' : null,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    badge,
                  ],
                ],
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildPrivilegeRow({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF10B981),
          size: 18,
        ),
      ],
    );
  }
}


