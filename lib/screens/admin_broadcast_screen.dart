
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
// Step 5: Audience Filtering & Visual Styling Helpers
bool get _isCategoryAudience => _audience.startsWith(_categoryPrefix);

String? get _selectedCategory {
  if (!_isCategoryAudience) {
    return null;
  }
  return _audience.substring(_categoryPrefix.length);
}

String get _audienceName {
  if (_audience == NotificationTopics.allUsers) {
    return 'Everyone';
  }
  if (_audience == NotificationTopics.admins) {
    return 'Admins only';
  }
  if (_isCategoryAudience) {
    return _selectedCategory ?? 'Selected category';
  }
  return 'Selected audience';
}

IconData get _audienceIcon {
  if (_audience == NotificationTopics.admins) {
    return Icons.admin_panel_settings_outlined;
  }
  if (_isCategoryAudience) {
    return Icons.work_outline_rounded;
  }
  return Icons.groups_2_outlined;
}

Color _getAudienceColor(_BroadcastColors colors) {
  if (_audience == NotificationTopics.admins) {
    return const Color(0xFF8B5CF6);
  }
  if (_isCategoryAudience) {
    return colors.isDark ? const Color(0xFF34D399) : const Color(0xFF0F766E);
  }
  return colors.primary;
}

Color _getAudienceBackground(_BroadcastColors colors) {
  if (_audience == NotificationTopics.admins) {
    return colors.isDark ? const Color(0x338B5CF6) : const Color(0xFFF3E8FF);
  }
  if (_isCategoryAudience) {
    return colors.isDark ? const Color(0x3310B981) : const Color(0xFFECFDF5);
  }
  return colors.isDark ? const Color(0x33059669) : const Color(0xFFE8F7F0);
}

String _audienceDescription() {
  if (_audience == NotificationTopics.admins) {
    return 'Only CareerWise administrators will receive this announcement.';
  }
  if (_isCategoryAudience) {
    return 'Targeting candidates subscribed or interested in ${_selectedCategory ?? 'this category'}.';
  }
  return 'Broadcast will be delivered to every active user across the platform.';
}




