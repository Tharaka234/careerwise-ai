
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
// Step 6: Announcement Broadcast Dispatch Logic


Future<void> _send(_BroadcastColors colors) async {
  FocusScope.of(context).unfocus();

  if (!_formKey.currentState!.validate()) {
    return;
  }

  final confirmed = await _showConfirmation(colors);

  if (confirmed != true) {
    return;
  }

  setState(() {
    _isSending = true;
  });

  try {
    final result =
    await NotificationService.instance.broadcastAnnouncement(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      topic: _isCategoryAudience
          ? NotificationTopics.allUsers
          : _audience,
      category: _isCategoryAudience ? _selectedCategory : null,
    );

    if (!mounted) return;

    switch (result) {
      case PushResult.sent:
        _showSuccessMessage();
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _audience = NotificationTopics.allUsers;
        });
        break;

      case PushResult.notConfigured:
        _showSnack(
          'Announcement saved to history, but push notification delivery is not configured.',
          error: true,
        );
        break;

      default:
        _showSnack(
          'Could not send the announcement. Please check the debug console.',
          error: true,
        );
    }
  } catch (e) {
    if (!mounted) return;
    _showSnack(
      'Something went wrong while sending the announcement: $e',
      error: true,
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }
}
// Step 7: Pre-Send Confirmation Modal Bottom Sheet


Future<bool?> _showConfirmation(_BroadcastColors colors) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.cardBorder,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 22),

              // Icon badge
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: colors.iconBoxBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: colors.primary,
                  size: 34,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Send Announcement?',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'This broadcast will be dispatched to $_audienceName.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 18),

              // Mini preview container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: colors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.trim(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _bodyController.text.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        minimumSize: const Size(0, 50),
                        side: BorderSide(color: colors.cardBorder, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors.isDark
                              ? const [Color(0xFF059669), Color(0xFF047857)]
                              : const [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, true),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Send Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}




