
// Step 1: Imports and Dependencies


import 'package:flutter/material.dart';

import 'package:careerwise-ai/services/notification_service.dart';
import 'package:careerwise-ai/services/notification_types.dart';
import 'package:careerwise-ai/services/push_sender.dart';
import 'admin_profile_screen.dart';


// Step 2: Dynamic Theme Color Palette (Premium Emerald Green Theme)


class _BroadcastColors {
  final bool isDark;

  const _BroadcastColors({required this.isDark});

  // Backgrounds:
  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Inputs
  Color get inputBg => isDark ? const Color(0xFF0E1A14) : const Color(0xFFF7FAF8);
  Color get inputBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFE2EFE7);

  // Brand / Emerald Accent Colors
  Color get primary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get primaryAccent => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get primaryDark => isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary => isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);
  Color get textSecondary => isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);
  Color get textMuted => isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Icon Boxes & Badges
  Color get iconBoxBg => isDark ? const Color(0x3310B981) : const Color(0x1F059669);
}

// Step 3: Main Screen Widget Skeleton (StatefulWidget)


/// Admin-only screen used to send CareerWise announcements.
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

// Step 4: State Management, Form Key, Controllers & Lifecycle

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  static const String _categoryPrefix = 'category:';

  String _audience = NotificationTopics.allUsers;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}




