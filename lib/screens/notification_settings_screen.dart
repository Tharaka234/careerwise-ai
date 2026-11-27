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

  // =========================================================
  // ANNOUNCEMENTS
  // =========================================================

  Future<void> _toggleAnnouncements(bool value) async {
    final previous = prefs;

    setState(() {
      prefs = NotificationPrefs(
        announcements: value,
        categories: prefs.categories,
        isAdmin: prefs.isAdmin,
      );
    });

    try {
      await NotificationService.instance.setAnnouncementsEnabled(value);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        prefs = previous;
      });

      _snack(
        'Could not update announcement settings.',
        error: true,
      );
    }
  }

  // =========================================================
  // JOB CATEGORY
  // =========================================================

  Future<void> _toggleCategory(
      String category,
      bool selected,
      ) async {
    final previous = prefs;

    final updated = Set<String>.from(prefs.categories);

    if (selected) {
      updated.add(category);
    } else {
      updated.remove(category);
    }

    setState(() {
      prefs = NotificationPrefs(
        announcements: prefs.announcements,
        categories: updated,
        isAdmin: prefs.isAdmin,
      );
    });

    try {
      await NotificationService.instance.setCategorySubscribed(
        category,
        selected,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        prefs = previous;
      });

      _snack(
        'Could not update job alerts.',
        error: true,
      );
    }
  }

  // =========================================================
  // NOTIFICATION PERMISSION
  // =========================================================

  Future<void> _enablePermission() async {
    await NotificationService.instance.requestPermission();

    final allowed =
    await NotificationService.instance.areNotificationsAllowed();

    if (!mounted) return;

    setState(() {
      permissionAllowed = allowed;
    });

    if (allowed) {
      _snack('Notifications enabled successfully.');
    } else {
      _snack(
        'Please enable CareerWise notifications in your device settings.',
        error: true,
      );
    }
  }

  // =========================================================
  // ADMIN TEST PUSH
  // =========================================================

  Future<void> _sendTest() async {
    setState(() {
      isSendingTest = true;
    });

    try {
      final message = await NotificationService.instance.sendTestPush();

      if (!mounted) return;

      _snack(message);
    } catch (e) {
      if (!mounted) return;

      _snack(
        'Failed to send test push: $e',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSendingTest = false;
        });
      }
    }
  }

  // =========================================================
  // COPY FCM TOKEN
  // =========================================================

  Future<void> _copyFcmToken() async {
    try {
      final token = await NotificationService.instance.getDeviceToken();

      if (token == null) {
        _snack(
          'No FCM token is available on this device.',
          error: true,
        );
        return;
      }

      await Clipboard.setData(
        ClipboardData(text: token),
      );

      _snack('FCM device token copied.');
    } catch (e) {
      _snack(
        'Could not copy FCM token.',
        error: true,
      );
    }
  }

  // =========================================================
  // HEADER BUTTON
  // =========================================================

  Widget _headerButton(
      IconData icon,
      VoidCallback onTap,
      ) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
        onPressed: onTap,
      ),
    );
  }

  // =========================================================
  // SECTION LABEL
  // =========================================================

  Widget _sectionLabel(
      String title,
      String subtitle,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _colors.isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SWITCH SETTING
  // =========================================================

  Widget _switchSetting({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            color: _colors.isDark
                ? iconColor.withValues(alpha: 0.16)
                : iconBackground,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _colors.isDark
              ? const Color(0xFF334155)
              : const Color(0xFFCBD5E1),
        ),
      ],
    );
  }

  // =========================================================
  // STANDARD CARD
  // =========================================================

  Widget _settingCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(17),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: _colors.isDark ? 0.25 : 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // =========================================================
  // PRIVACY NOTE
  // =========================================================

  Widget _privacyNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF94A3B8),
          size: 13,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            prefs.isAdmin
                ? 'Admin notification preferences are securely managed.'
                : 'You can change your notification preferences anytime.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PREMIUM HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF044E36),
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -45,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -55,
            bottom: -70,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 65,
            bottom: 35,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _headerButton(
                        Icons.arrow_back_ios_new_rounded,
                            () {
                          Navigator.maybePop(context);
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.13),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: permissionAllowed
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFDBA74),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              permissionAllowed ? 'Active' : 'Permission off',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 31),
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Personalize your alerts & updates',
                              style: TextStyle(
                                color: Color(0xFFD1FAE5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            prefs.isAdmin
                                ? 'Admin Mode: Broadcast & device diagnostics active.'
                                : 'Tailor your preferences for relevant career alerts.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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