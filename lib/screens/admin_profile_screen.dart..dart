
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

