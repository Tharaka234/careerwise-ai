import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:careerwise_ai/services/notification_service.dart';
import 'package:careerwise_ai/services/notification_types.dart';
import 'admin_profile_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  _NotificationSettingsColors _colors = _NotificationSettingsColors.of(false);

  Color get primary => _colors.primary;
  Color get primaryDark => _colors.primaryDark;
  Color get indigo => _colors.indigo;
  Color get background => _colors.background;
  Color get cardBg => _colors.cardBg;
  Color get textPrimary => _colors.textPrimary;
  Color get textSecondary => _colors.textSecondary;
  Color get border => _colors.border;

  // =========================================================
  // STATE
  // =========================================================

  bool isLoading = true;
  bool permissionAllowed = true;
  bool isSendingTest = false;
  String? loadError;

  NotificationPrefs prefs = const NotificationPrefs(
    announcements: true,
    categories: <String>{},
    isAdmin: false,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  // =========================================================
  // LOAD SETTINGS
  // =========================================================

  Future<void> _load() async {
    try {
      final loaded = await NotificationService.instance.loadPrefs();

      final allowed =
      await NotificationService.instance.areNotificationsAllowed();

      if (!mounted) return;

      setState(() {
        prefs = loaded;

        permissionAllowed = allowed || !NotificationService.isSupported;

        isLoading = false;
        loadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadError = '$e';
        isLoading = false;
      });
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _snack(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: error ? const Color(0xFFDC2626) : primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // TEMPORARY: replaced by the real build() in the final screen commit.
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

class _NotificationSettingsColors {
  final bool isDark;
  final Color primary;
  final Color primaryDark;
  final Color indigo;
  final Color background;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final Color chipBg;
  final Color chipBorder;
  final Color iconBgMuted;

  const _NotificationSettingsColors({
    required this.isDark,
    required this.primary,
    required this.primaryDark,
    required this.indigo,
    required this.background,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.chipBg,
    required this.chipBorder,
    required this.iconBgMuted,
  });

  factory _NotificationSettingsColors.of(bool isDark) {
    if (isDark) {
      return const _NotificationSettingsColors(
        isDark: true,
        primary: Color(0xFF10B981),
        primaryDark: Color(0xFF044E36),
        indigo: Color(0xFF34D399),
        background: Color(0xFF0A140F),
        cardBg: Color(0xFF13231B),
        textPrimary: Color(0xFFF1F5F9),
        textSecondary: Color(0xFF94A3B8),
        border: Color(0xFF1E3A2B),
        divider: Color(0xFF1E3A2B),
        chipBg: Color(0xFF162E22),
        chipBorder: Color(0xFF234C37),
        iconBgMuted: Color(0x3310B981),
      );
    }
    return const _NotificationSettingsColors(
      isDark: false,
      primary: Color(0xFF059669),
      primaryDark: Color(0xFF044E36),
      indigo: Color(0xFF10B981),
      background: Color(0xFFF0FDF4),
      cardBg: Colors.white,
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF64748B),
      border: Color(0xFFD1FAE5),
      divider: Color(0xFFEEF2F7),
      chipBg: Color(0xFFF8FAFC),
      chipBorder: Color(0xFFE5EAF1),
      iconBgMuted: Color(0xFFEEF4FF),
    );
  }
}