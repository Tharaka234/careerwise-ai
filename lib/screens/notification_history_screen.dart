import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:careerwise_ai/screens/notification_settings_screen.dart';
import 'package:careerwise_ai/services/notification_service.dart';
import 'package:careerwise_ai/services/notification_types.dart';
import 'admin_profile_screen.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  // =========================================================
  // FILTERS
  // =========================================================

  static const String filterAll = 'All';
  static const String filterJobs = 'Jobs';
  static const String filterUpdates = 'Updates';
  static const String filterAllApplications = 'All Applications';
  static const String filterAnnouncements = 'Announcements';

  String selectedFilter = filterAll;

  // =========================================================
  // DATA
  // =========================================================

  late Stream<List<NotificationHistoryItem>> _stream =
  NotificationService.instance.watchHistory();

  StreamSubscription<Set<String>>? _dismissedSubscription;

  Set<String> _dismissed = <String>{};

  List<NotificationHistoryItem> _currentVisibleItems = const [];

  // The role (admin / job seeker) is read from Firestore before anything is
  // shown, so an admin can never briefly see the job-seeker list.
  bool _roleReady = false;

  void _retryNotifications() {
    setState(() {
      _stream = NotificationService.instance.watchHistory();
    });
  }

  @override
  void initState() {
    super.initState();

    NotificationService.instance.refreshAdminStatus().then((_) {
      if (mounted) setState(() => _roleReady = true);
    }).catchError((Object error) {
      debugPrint('[NotificationHistoryScreen][role] $error');
      if (mounted) setState(() => _roleReady = true);
    });

    _dismissedSubscription =
        NotificationService.instance.watchDismissedHistory().listen(
              (ids) {
            if (!mounted) return;

            setState(() {
              _dismissed = ids;
            });
          },
          onError: (Object error, StackTrace stack) {
            debugPrint('[NotificationHistoryScreen][dismissed] $error');
            debugPrintStack(stackTrace: stack);
          },
        );
  }

  @override
  void dispose() {
    _dismissedSubscription?.cancel();
    super.dispose();
  }

  // =========================================================
  // VISIBILITY
  // =========================================================

  bool _visibleToUser(NotificationHistoryItem item) {
    if (!_roleReady) return false;
    if (_dismissed.contains(item.id)) return false;

    // Admin: Show only new job applications.
    if (NotificationService.instance.isAdmin) {
      return item.audience == HistoryAudience.admins &&
          (item.type == NotificationTypes.newApplication ||
              item.type == NotificationTypes.cancelRequest);
    }

    // Job seekers see public/category items and their own private updates.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return item.audience == HistoryAudience.everyone ||
        item.audience == HistoryAudience.category ||
        (item.audience == HistoryAudience.user &&
            uid != null &&
            item.recipientUid == uid);
  }

  // =========================================================
  // FILTER
  // =========================================================

  bool _matchesFilter(NotificationHistoryItem item) {
    // Admin sees only new application notifications.
    if (NotificationService.instance.isAdmin) {
      return item.type == NotificationTypes.newApplication ||
          item.type == NotificationTypes.cancelRequest;
    }

    switch (selectedFilter) {
      case filterJobs:
        return item.type == NotificationTypes.newJob;

      case filterUpdates:
        return item.type == NotificationTypes.jobUpdated ||
            item.type == NotificationTypes.jobDeleted ||
            item.type == NotificationTypes.applicationStatus;

      case filterAnnouncements:
        return item.type == NotificationTypes.announcement;

      case filterAll:
      default:
        return true;
    }
  }

  int _filterCount(
      List<NotificationHistoryItem> items,
      String filter,
      ) {
    if (filter == filterAllApplications) {
      return items
          .where((item) =>
      item.type == NotificationTypes.newApplication ||
          item.type == NotificationTypes.cancelRequest)
          .length;
    }

    switch (filter) {
      case filterJobs:
        return items
            .where((item) => item.type == NotificationTypes.newJob)
            .length;

      case filterUpdates:
        return items
            .where((item) =>
        item.type == NotificationTypes.jobUpdated ||
            item.type == NotificationTypes.jobDeleted ||
            item.type == NotificationTypes.applicationStatus)
            .length;

      case filterAnnouncements:
        return items
            .where((item) => item.type == NotificationTypes.announcement)
            .length;

      default:
        return items.length;
    }
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _deleteNotifications(
      List<NotificationHistoryItem> items,
      ) async {
    if (items.isEmpty) return;

    final ids = items.map((item) => item.id).toList();

    setState(() {
      _dismissed = {
        ..._dismissed,
        ...ids,
      };
    });

    try {
      await NotificationService.instance.dismissHistory(ids);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _dismissed = _dismissed.difference(ids.toSet());
      });

      _showMessage(
        'Could not remove notification.',
        error: true,
      );

      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF042618),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          content: Text(
            ids.length == 1
                ? 'Notification removed'
                : '${ids.length} notifications removed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFF6EE7B7),
            onPressed: () {
              if (!mounted) return;

              setState(() {
                _dismissed = _dismissed.difference(ids.toSet());
              });

              NotificationService.instance.restoreHistory(ids);
            },
          ),
        ),
      );
  }

  // =========================================================
  // CLEAR ALL BOTTOM SHEET
  // =========================================================

  Future<void> _showClearConfirmation(_NotificationColors colors) async {
    if (_currentVisibleItems.isEmpty) {
      _showMessage('No notifications to clear.');
      return;
    }

    final bool? shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.cardBorder, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.cardBorder,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.delete_sweep_outlined,
                    size: 34,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Clear notifications?',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This will remove ${_currentVisibleItems.length} '
                      'notification${_currentVisibleItems.length == 1 ? '' : 's'} '
                      'currently shown in your notification history.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          side: BorderSide(color: colors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                        ),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
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

    if (shouldDelete == true) {
      await _deleteNotifications(_currentVisibleItems);
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor:
          error ? const Color(0xFFDC2626) : const Color(0xFF042618),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  // =========================================================
  // TIME
  // =========================================================

  String _timeAgo(DateTime? time) {
    if (time == null) {
      return 'Just now';
    }

    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${time.day}/${time.month}/${time.year}';
  }

  // =========================================================
  // RECENT INDICATOR
  // =========================================================

  bool _isRecent(DateTime? time) {
    if (time == null) return true;

    final difference = DateTime.now().difference(time);

    return difference.inHours < 12;
  }

  // =========================================================
  // NOTIFICATION STYLE
  // =========================================================

  _NotificationStyle _getNotificationStyle(
      NotificationHistoryItem item,
      bool isDark,
      ) {
    if (item.type == NotificationTypes.newJob) {
      return _NotificationStyle(
        label: 'New opportunity',
        icon: Icons.work_outline_rounded,
        color: const Color(0xFF059669),
        background: isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.40)
            : const Color(0xFFD1FAE5),
      );
    }

    if (item.type == NotificationTypes.jobUpdated) {
      return _NotificationStyle(
        label: 'Job updated',
        icon: Icons.auto_awesome_outlined,
        color: const Color(0xFFD97706),
        background: isDark
            ? const Color(0xFF78350F).withValues(alpha: 0.35)
            : const Color(0xFFFEF3C7),
      );
    }

    if (item.type == NotificationTypes.jobDeleted) {
      return _NotificationStyle(
        label: 'Job removed',
        icon: Icons.work_off_outlined,
        color: const Color(0xFFEF4444),
        background: isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
            : const Color(0xFFFEE2E2),
      );
    }

    if (item.type == NotificationTypes.applicationStatus) {
      return _NotificationStyle(
        label: 'Application update',
        icon: Icons.assignment_turned_in_outlined,
        color: const Color(0xFF2563EB),
        background:
        isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
      );
    }

    if (item.type == NotificationTypes.cancelRequest) {
      return _NotificationStyle(
        label: 'Cancellation request',
        icon: Icons.event_busy_outlined,
        color: const Color(0xFFD97706),
        background: isDark
            ? const Color(0xFF78350F).withValues(alpha: 0.35)
            : const Color(0xFFFEF3C7),
      );
    }

    if (item.type == NotificationTypes.newApplication) {
      return _NotificationStyle(
        label: 'New Application',
        icon: Icons.person_add_alt_1_outlined,
        color: const Color(0xFF2563EB),
        background:
        isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
      );
    }

    return _NotificationStyle(
      label: 'Announcement',
      icon: Icons.campaign_outlined,
      color: const Color(0xFF10B981),
      background: isDark
          ? const Color(0xFF064E3B).withValues(alpha: 0.40)
          : const Color(0xFFECFDF5),
    );
  }
}

// ===========================================================
// NOTIFICATION COLORS HELPER
// ===========================================================

class _NotificationColors {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color accent;
  final Color chipBg;
  final Color chipBorder;
  final Color countBg;

  _NotificationColors({required this.isDark})
      : pageBg = isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4),
        cardBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        cardBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFE2E8F0),
        textPrimary = isDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        primary = const Color(0xFF059669),
        accent = const Color(0xFF10B981),
        chipBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        chipBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        countBg = isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.40)
            : const Color(0xFFD1FAE5);
}

// ===========================================================
// NOTIFICATION STYLE MODEL
// ===========================================================

class _NotificationStyle {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _NotificationStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });
}