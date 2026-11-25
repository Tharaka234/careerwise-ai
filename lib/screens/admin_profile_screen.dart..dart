
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

