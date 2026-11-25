
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
