import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_profile_screen.dart';
import 'admin_users_screen.dart';
import 'admin_recommendations_screen.dart';
import 'add_job_screen.dart';
import 'package:flutter/services.dart';
import 'admin_broadcast_screen.dart';
import 'notification_history_screen.dart';
import '../widgets/cancel_request_banner.dart';


class _AdminColors {
  final bool isDark;

  const _AdminColors({required this.isDark});

  // Background Colors
  Color get pageBg =>
      isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);

  Color get cardBg =>
      isDark ? const Color(0xFF13231B) : Colors.white;

  Color get cardBorder =>
      isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);

  Color get appBarBg =>
      isDark ? const Color(0xFF0E1B15) : Colors.white;

  Color get appBarBorder =>
      isDark ? const Color(0xFF1A3325) : const Color(0xFFE2EFE7);

  // Brand Colors
  Color get primary =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

  Color get primaryAccent =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);

  Color get primaryDark =>
      isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary =>
      isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);

  Color get textSecondary =>
      isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);

  Color get textMuted =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Dividers and Badges
  Color get divider =>
      isDark ? const Color(0xFF1C3426) : const Color(0xFFE5EFE9);

  Color get badgeBg =>
      isDark ? const Color(0x3310B981) : const Color(0x1F059669);

  Color get badgeText =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
}

// =====================================================
// ADMIN DASHBOARD SCREEN
// =====================================================

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final GlobalKey _jobsSectionKey = GlobalKey();
  final GlobalKey _applicationsSectionKey = GlobalKey();

  bool _showAllJobs = false;
  bool _showAllApplications = false;

  void _scrollToSection(GlobalKey key) {
    final targetContext = key.currentContext;

    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  // CHECK ADMIN
  Future<DocumentSnapshot?> _getAdminDocument() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
  }
  // GET APPLICANT USER DATA
  Future<Map<String, dynamic>?> _getUserData(
      String userId,
      ) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      return null;
    }
  }
  // =====================================================
// REMOVE CANCELLED APPLICATION
// =====================================================

  Future<void> _confirmRemoveCancelledApplication(
      BuildContext context,
      String applicationId,
      String jobTitle,
      _AdminColors colors,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.cardBg,

        title: Text(
          'Remove Cancelled Application?',
          style: TextStyle(
            color: colors.textPrimary,
          ),
        ),

        content: Text(
          'Remove the cancelled application for "$jobTitle" '
              'from the Admin Dashboard?\n\n'
              'The cancellation record will be preserved.',

          style: TextStyle(
            color: colors.textSecondary,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),

            child: const Text('Keep'),
          ),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),

            onPressed: () =>
                Navigator.pop(dialogContext, true),

            icon: const Icon(Icons.delete_outline),

            label: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Check authenticated admin
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw StateError('Not signed in');
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!adminDoc.exists ||
          adminDoc.data()?['role'] != 'admin') {
        throw StateError(
          'Administrator access required',
        );
      }

      // Get application document
      final ref = FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId);

      // Archive cancelled application safely
      await FirebaseFirestore.instance.runTransaction(
            (transaction) async {
          final snapshot = await transaction.get(ref);

          if (!snapshot.exists) {
            throw StateError(
              'Application no longer exists',
            );
          }

          final data = snapshot.data()!;

          final status = (data['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          if (status != 'cancelled') {
            throw StateError(
              'Only cancelled applications can be removed',
            );
          }

          if (data['adminArchived'] == true) return;

          transaction.update(ref, {
            'adminArchived': true,
            'adminArchivedAt':
            FieldValue.serverTimestamp(),
            'adminArchivedBy': uid,
          });
        },
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cancelled application removed from Admin Dashboard',
          ),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to remove application: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _AdminColors(isDark: isDark);

        return FutureBuilder<DocumentSnapshot?>(
          future: _getAdminDocument(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: colors.pageBg,
                body: Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                backgroundColor: colors.pageBg,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error checking admin access:\n\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists) {
              return _accessDeniedScreen(
                'You are not an administrator.',
                colors,
              );
            }

            final data =
            snapshot.data!.data() as Map<String, dynamic>?;

            if (data?['role'] != 'admin') {
              return _accessDeniedScreen(
                'You are not an administrator.',
                colors,
              );
            }

            final adminName =
            data?['name']?.toString().trim().isNotEmpty == true
                ? data!['name'].toString()
                : 'Admin';

            return _buildDashboard(
              context,
              adminName,
              colors,
            );
          },
        );
      },
    );
  }
  // =====================================================
// ACCESS DENIED
// =====================================================

  Widget _accessDeniedScreen(
      String message,
      _AdminColors colors,
      ) {
    return Scaffold(
      backgroundColor: colors.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.cardBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: colors.isDark ? 0.3 : 0.06,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Access Denied',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// MAIN DASHBOARD



// ADMIN PROFILE
  void _showAdminProfile(
      BuildContext context,
      String adminName,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProfileScreen(
          adminName: adminName,
        ),
      ),
    );
  }

  // =====================================================
// MAIN DASHBOARD
// =====================================================

  Widget _buildDashboard(
      BuildContext context,
      String adminName,
      _AdminColors colors,
      ) {
    return Scaffold(
      backgroundColor: colors.pageBg,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: colors.appBarBg,
        surfaceTintColor: colors.appBarBg,
        titleSpacing: 14,

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: colors.appBarBorder,
            height: 1,
          ),
        ),

        title: LayoutBuilder(
          builder: (context, constraints) {
            final showAdminBadge =
                constraints.maxWidth >= 215;

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors.isDark
                          ? const [
                        Color(0xFF047857),
                        Color(0xFF059669),
                      ]
                          : const [
                        Color(0xFF059669),
                        Color(0xFF10B981),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(
                          alpha: 0.3,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Flexible(
                  child: Text(
                    'CareerWise',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),

                if (showAdminBadge) ...[
                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.primary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        color: colors.badgeText,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        actions: [
          // Theme Toggle Button
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 2,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: colors.isDark ? 0.2 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: colors.isDark
                  ? 'Switch to Light Theme'
                  : 'Switch to Dark Theme',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: child.key ==
                        const ValueKey('dark_icon_admin')
                        ? Tween<double>(
                      begin: 0.75,
                      end: 1.0,
                    ).animate(animation)
                        : Tween<double>(
                      begin: 0.25,
                      end: 0.0,
                    ).animate(animation),
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: colors.isDark
                    ? const Icon(
                  Icons.wb_sunny_rounded,
                  key: ValueKey('dark_icon_admin'),
                  color: Color(0xFFFDE047),
                  size: 20,
                )
                    : Icon(
                  Icons.nightlight_round,
                  key: const ValueKey('light_icon_admin'),
                  color: colors.primary,
                  size: 20,
                ),
              ),
              onPressed: () {
                AdminThemeManager.isDarkMode.value =
                !AdminThemeManager.isDarkMode.value;
              },
            ),
          ),

          // Admin Profile Button
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 2,
            ),
            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: colors.isDark ? 0.2 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Admin Profile',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              onPressed: () {
                _showAdminProfile(context, adminName);
              },
              icon: Icon(
                Icons.person_rounded,
                color: colors.primary,
                size: 20,
              ),
            ),
          ),
          // Notification History Button
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 2,
            ),

            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: colors.isDark ? 0.2 : 0.08,
              ),
              shape: BoxShape.circle,
            ),

            child: IconButton(
              tooltip: 'Notification History',
              padding: EdgeInsets.zero,

              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),

              icon: Icon(
                Icons.notifications_outlined,
                color: colors.primary,
                size: 21,
              ),

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const NotificationHistoryScreen(),
                  ),
                );
              },
            ),
          ),
          // Broadcast Announcement Button
          Container(
            margin: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 2,
            ),

            decoration: BoxDecoration(
              color: colors.primary.withValues(
                alpha: colors.isDark ? 0.2 : 0.08,
              ),
              shape: BoxShape.circle,
            ),

            child: IconButton(
              tooltip: 'Send announcement',
              padding: EdgeInsets.zero,

              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),

              icon: Icon(
                Icons.campaign_outlined,
                color: colors.primary,
                size: 22,
              ),

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const AdminBroadcastScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeBanner(
                context,
                adminName,
                colors,
              ),

              const SizedBox(height: 28),

              // Dashboard Overview
              _sectionHeader(
                title: 'Dashboard Overview',
                subtitle: 'Real-time metrics & insights',
                icon: Icons.dashboard_outlined,
                colors: colors,
              ),


              const SizedBox(height: 16),

             // Real-time Statistics
              _statisticsGrid(colors),


              const SizedBox(height: 34),

              // JOB MANAGEMENT HEADER
              Container(
                key: _jobsSectionKey,
                child: _sectionHeader(
                  title: 'Job Management',
                  subtitle: 'Manage and publish career opportunities',
                  icon: Icons.work_outline_rounded,
                  colors: colors,
                  streamCollection: 'jobs',
                  countSuffix: 'Active Jobs',
                ),
              ),

              const SizedBox(height: 16),

             // ADD JOB BUTTON
              _addJobButton(
                context: context,
                colors: colors,
              ),

              const SizedBox(height: 16),

             // JOBS LIST
              _jobsList(context, colors),

              const SizedBox(height: 36),

              // JOB APPLICATIONS SECTION
              Container(
                key: _applicationsSectionKey,
                child: _sectionHeader(
                  title: 'Job Applications',
                  subtitle: 'Review applicants & track hiring pipeline',
                  icon: Icons.groups_outlined,
                  colors: colors,
                  streamCollection: 'applications',
                  countSuffix: 'Applicants',
                ),
              ),

              const SizedBox(height: 16),

              _applicationsList(colors),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // WELCOME BANNER


  Widget _welcomeBanner(
      BuildContext context,
      String adminName,
      _AdminColors colors,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 20 : 24),

          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors.isDark
                  ? const [
                Color(0xFF064E3B),
                Color(0xFF047857),
                Color(0xFF065F46),
              ]
                  : const [
                Color(0xFF065F46),
                Color(0xFF059669),
                Color(0xFF10B981),
              ],
            ),

            borderRadius: BorderRadius.circular(24),

            border: Border.all(
              color: Colors.white.withValues(
                alpha: colors.isDark ? 0.15 : 0.25,
              ),
              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(
                  alpha: colors.isDark ? 0.25 : 0.35,
                ),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.18,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Good to see you 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrow ? 26 : 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isNarrow
                          ? 'Manage jobs, applications and career recommendations.'
                          : 'Manage jobs, applications and\ncareer recommendations from here.',
                      maxLines: isNarrow ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.9,
                        ),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: EdgeInsets.all(
                  isNarrow ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.18,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.3,
                    ),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: isNarrow ? 36 : 42,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // SECTION HEADER
  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required _AdminColors colors,
    String? streamCollection,
    String? countSuffix,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primary.withValues(
              alpha: colors.isDark ? 0.2 : 0.12,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        if (streamCollection != null) ...[
          const SizedBox(width: 8),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(streamCollection)
                .snapshots(),

            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      '$count ${countSuffix ?? ''}'.trim(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
  // STATISTICS GRID
  Widget _statisticsGrid(_AdminColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
        constraints.maxWidth >= 750 ? 4 : 2;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent:
            constraints.maxWidth >= 750 ? 150 : 154,
          ),

          children: [
            // TOTAL USERS
            _statCard(
              collection: 'users',
              title: 'Total Users',
              icon: Icons.people_alt_outlined,
              color: colors.isDark
                  ? const Color(0xFF34D399)
                  : const Color(0xFF059669),
              colors: colors,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminUsersScreen(),
                  ),
                );
              },
            ),

            // TOTAL JOBS
            _statCard(
              collection: 'jobs',
              title: 'Total Jobs',
              icon: Icons.work_outline_rounded,
              color: colors.isDark
                  ? const Color(0xFF22D3EE)
                  : const Color(0xFF0891B2),
              colors: colors,
              onTap: () => _scrollToSection(_jobsSectionKey),
            ),

            // APPLICATIONS
            _statCard(
              collection: 'applications',
              title: 'Applications',
              icon: Icons.description_outlined,
              color: colors.isDark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFFD97706),
              colors: colors,
              onTap: () =>
                  _scrollToSection(_applicationsSectionKey),
            ),

            // AI RECOMMENDATIONS
            _statCard(
              collection: 'career_recommendations',
              title: 'AI Recommendations',
              icon: Icons.psychology_outlined,
              color: colors.isDark
                  ? const Color(0xFFC084FC)
                  : const Color(0xFF7C3AED),
              colors: colors,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const AdminRecommendationsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  // REAL-TIME STAT CARD
  Widget _statCard({
    required String collection,
    required String title,
    required IconData icon,
    required Color color,
    required _AdminColors colors,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .snapshots(),

      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        final countLabel = snapshot.hasError
            ? 'Error'
            : snapshot.connectionState == ConnectionState.waiting
            ? '...'
            : '$count';

        return Container(
          decoration: BoxDecoration(
            color: colors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (
                    colors.isDark
                        ? Colors.black
                        : const Color(0xFF059669)
                ).withValues(
                  alpha: colors.isDark ? 0.35 : 0.05,
                ),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),

            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              mouseCursor: SystemMouseCursors.click,

              splashColor: color.withValues(alpha: 0.14),
              highlightColor: color.withValues(alpha: 0.06),

              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: colors.isDark ? 0.22 : 0.12,
                            ),
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),

                          child: Icon(
                            icon,
                            color: color,
                            size: 22,
                          ),
                        ),

                        // Navigation Arrow
                        Container(
                          width: 32,
                          height: 32,

                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: colors.isDark ? 0.18 : 0.08,
                            ),
                            borderRadius:
                            BorderRadius.circular(10),
                            border: Border.all(
                              color: color.withValues(
                                alpha: colors.isDark ? 0.3 : 0.22,
                              ),
                            ),
                          ),

                          child: Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Real-time Firestore Count
                    Text(
                      countLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.0,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.0,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  // ADD JOB HERO ACTION CARD (PREMIUM CALLOUT DESIGN)
  Widget _addJobButton({
    required BuildContext context,
    required _AdminColors colors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF065F46)]
              : const [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: colors.isDark ? 0.15 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: colors.isDark ? 0.35 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddJobScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Post a New Career Opportunity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Publish openings & attract qualified talent',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: colors.primaryDark,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Job',
                        style: TextStyle(
                          color: colors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // JOB LIST
  Widget _jobsList(BuildContext context, _AdminColors colors) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingCard(colors);
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Error loading jobs:\n\n${snapshot.error}',
            colors,
          );
        }

        final jobs = snapshot.data?.docs ?? [];

        if (jobs.isEmpty) {
          return _emptyCard(
            icon: Icons.work_off_outlined,
            title: 'No jobs found',
            subtitle: 'Add your first job using the button above.',
            colors: colors,
          );
        }

        final visibleJobs = _showAllJobs
            ? jobs
            : jobs.take(4).toList();

        return Column(
          children: [
            ...visibleJobs.map((document) {
              final data = document.data() as Map<String, dynamic>;

              return _jobCard(
                context,
                document.id,
                data,
                colors,
              );
            }),

            if (jobs.length > 4)
              _viewAllButton(
                colors: colors,
                showAll: _showAllJobs,
                totalCount: jobs.length,
                label: 'Jobs',
                onPressed: () {
                  setState(() {
                    _showAllJobs = !_showAllJobs;
                  });
                },
              ),
          ],
        );
      },
    );
  }
  // JOB CARD (REDESIGNED PREMIUM EXECUTIVE VIEW)
  Widget _jobCard(
      BuildContext context,
      String jobId,
      Map<String, dynamic> data,
      _AdminColors colors,
      ) {
    final title = data['title']?.toString() ?? 'Unknown Job';
    final company = data['company']?.toString() ?? 'Unknown Company';
    final location = data['location']?.toString() ?? 'Unknown Location';
    final salary = data['salary']?.toString() ?? 'Salary not specified';
    final jobType = data['jobType']?.toString() ?? 'Full Time';
    final description = data['description']?.toString() ?? '';

    // Company Avatar Initial
    final initial = company.trim().isNotEmpty
        ? company.trim()[0].toUpperCase()
        : (title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : 'J');

    // Job type color & dot indicator
    Color jobTypeColor = colors.primary;
    if (jobType.toLowerCase().contains('part')) {
      jobTypeColor = const Color(0xFFF59E0B);
    } else if (jobType.toLowerCase().contains('remote')) {
      jobTypeColor = const Color(0xFF8B5CF6);
    } else if (jobType.toLowerCase().contains('contract')) {
      jobTypeColor = const Color(0xFF06B6D4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                .withValues(alpha: colors.isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left decorative accent bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.primary,
                      colors.primaryAccent,
                    ],
                  ),
                ),
              ),

              // Main Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar, Title & Job Type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Company Initial Avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colors.isDark
                                    ? const [Color(0xFF064E3B), Color(0xFF059669)]
                                    : const [Color(0xFF059669), Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.business_rounded,
                                      size: 15,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        company,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Job Type Pill with glowing indicator dot
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: jobTypeColor.withValues(alpha: colors.isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: jobTypeColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: jobTypeColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: jobTypeColor.withValues(alpha: 0.6),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  jobType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: jobTypeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Location & Salary Pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _featurePill(
                            icon: Icons.location_on_rounded,
                            label: location,
                            iconColor: colors.primary,
                            colors: colors,
                          ),
                          _featurePill(
                            icon: Icons.payments_rounded,
                            label: salary,
                            iconColor: const Color(0xFF10B981),
                            colors: colors,
                          ),
                        ],
                      ),

                      // Description Container
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: colors.isDark
                                ? const Color(0xFF0F1E17)
                                : const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              height: 1.45,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      Divider(color: colors.divider, height: 1),

                      const SizedBox(height: 12),

                      // Action Buttons (Edit & Delete - Perfectly Aligned & Modern)
                      Row(
                        children: [
                          // 1. EDIT JOB BUTTON
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors.isDark
                                      ? [
                                    const Color(0xFF064E3B).withValues(alpha: 0.35),
                                    const Color(0xFF10B981).withValues(alpha: 0.18),
                                  ]
                                      : [
                                    const Color(0xFF059669).withValues(alpha: 0.12),
                                    const Color(0xFF10B981).withValues(alpha: 0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colors.primary.withValues(
                                    alpha: colors.isDark ? 0.45 : 0.35,
                                  ),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primary.withValues(
                                      alpha: colors.isDark ? 0.15 : 0.08,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _editJob(context, jobId, data),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 17,
                                          color: colors.primary,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          'Edit Job',
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 2. DELETE BUTTON
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors.isDark
                                      ? [
                                    Colors.redAccent.withValues(alpha: 0.28),
                                    Colors.redAccent.withValues(alpha: 0.14),
                                  ]
                                      : [
                                    Colors.redAccent.withValues(alpha: 0.12),
                                    Colors.redAccent.withValues(alpha: 0.06),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: colors.isDark ? 0.45 : 0.35,
                                  ),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(
                                      alpha: colors.isDark ? 0.15 : 0.08,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _confirmDeleteJob(
                                    context,
                                    jobId,
                                    title,
                                    colors,
                                  ),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.redAccent,
                                        ),
                                        SizedBox(width: 7),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            letterSpacing: 0.2,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
  // FEATURE PILL HELPER
  Widget _featurePill({
    required IconData icon,
    required String label,
    required Color iconColor,
    required _AdminColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.isDark
            ? const Color(0xFF0F1E17)
            : const Color(0xFFF4F9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // EDIT JOB
  Future<void> _editJob(
      BuildContext context,
      String jobId,
      Map<String, dynamic> data,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddJobScreen(
          jobId: jobId,
          existingJob: data,
        ),
      ),
    );
  }
  // DELETE CONFIRMATION
  void _confirmDeleteJob(
      BuildContext context,
      String jobId,
      String jobTitle,
      _AdminColors colors,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: colors.cardBorder, width: 1.2),
          ),
          title: Text(
            'Delete Job?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$jobTitle"?\n\nThis action cannot be undone.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _deleteJob(
                  context,
                  jobId,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  // DELETE JOB
  Future<void> _deleteJob(
      BuildContext context,
      String jobId,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job deleted successfully.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete job:\n$e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  // APPLICATION LIST
  Widget _applicationsList(_AdminColors colors) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingCard(colors);
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Error loading applications:\n\n${snapshot.error}',
            colors,
          );
        }

        final applications = (snapshot.data?.docs ?? [])
            .where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return data['adminArchived'] != true;
        })
            .toList();

        if (applications.isEmpty) {
          return _emptyCard(
            icon: Icons.description_outlined,
            title: 'No applications yet',
            subtitle:
            'Applications will appear here when users apply for jobs.',
            colors: colors,
          );
        }

        // Most recent applications first
        final sortedApplications = [...applications];

        sortedApplications.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aDate = aData['appliedAt'] as Timestamp?;
          final bDate = bData['appliedAt'] as Timestamp?;

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return bDate.compareTo(aDate);
        });

        final visibleApplications = _showAllApplications
            ? sortedApplications
            : sortedApplications.take(4).toList();

        return Column(
          children: [
            ...visibleApplications.map((document) {
              final data =
              document.data() as Map<String, dynamic>;

              return _applicationCard(
                context,
                document.id,
                data,
                colors,
              );
            }),

            if (sortedApplications.length > 4)
              _viewAllButton(
                colors: colors,
                showAll: _showAllApplications,
                totalCount: sortedApplications.length,
                label: 'Applications',
                onPressed: () {
                  setState(() {
                    _showAllApplications =
                    !_showAllApplications;
                  });
                },
              ),
          ],
        );
      },
    );
  }
  // =====================================================
// APPLICATION CARD
// =====================================================

  Widget _applicationCard(
      BuildContext context,
      String applicationId,
      Map<String, dynamic> data,
      _AdminColors colors,
      ) {
    final jobTitle =
        data['jobTitle']?.toString() ?? 'Unknown Job';

    final company =
        data['company']?.toString() ?? 'Unknown Company';
    final userId =
        data['userId']?.toString() ?? 'Unknown User';

    final status =
        data['status']?.toString() ?? 'Applied';

    final appliedAt = data['appliedAt'] is Timestamp
        ? data['appliedAt'] as Timestamp
        : null;

    // Application status color
    Color statusColor = const Color(0xFF3B82F6);

    switch (status.toLowerCase()) {
      case 'under review':
        statusColor = const Color(0xFFF59E0B);
        break;

      case 'shortlisted':
        statusColor = const Color(0xFF8B5CF6);
        break;

      case 'interview':
      case 'interviewed':
        statusColor = const Color(0xFF06B6D4);
        break;

      case 'accepted':
      case 'hired':
        statusColor = const Color(0xFF10B981);
        break;

      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;

      case 'cancelled':
        statusColor = const Color(0xFF6B7280);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color: (
                colors.isDark
                    ? Colors.black
                    : const Color(0xFF059669)
            ).withValues(
              alpha: colors.isDark ? 0.35 : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),

        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // Left status accent bar
              Container(
                width: 5,
                color: statusColor,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // APPLICATION HEADER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: statusColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                              BorderRadius.circular(14),
                            ),

                            child: Icon(
                              Icons.description_outlined,
                              color: statusColor,
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [
                                Text(
                                  jobTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,

                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  company,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,

                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // STATUS BADGE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color: statusColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),

                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Candidate Identity Card
                      _applicantIdentityBox(
                        context,
                        userId,
                        colors,
                      ),


                      const SizedBox(height: 12),

                      // Recruitment Pipeline or Cancelled Notice
                      status.trim().toLowerCase() == 'cancelled'
                          ? CancelledApplicationNotice(
                        isDark: colors.isDark,
                        textColor: colors.textPrimary,
                      )
                          : _buildApplicationPipeline(
                        status,
                        colors,
                      ),
                      const SizedBox(height: 12),

                      Divider(
                        color: colors.divider,
                        height: 1,
                      ),

                      const SizedBox(height: 14),

                      // APPLIED DATE
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: colors.textSecondary,
                          ),

                          const SizedBox(width: 7),

                          Text(
                            appliedAt != null
                                ? 'Applied on ${_formatDate(appliedAt)}'
                                : 'Applied date unavailable',

                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Applicant Cancellation Request
                      CancelRequestBanner(
                        applicationId: applicationId,
                        data: data,
                        isDark: colors.isDark,
                        textColor: colors.textPrimary,
                        mutedColor: colors.textSecondary,
                      ),

                      // REMOVE CANCELLED APPLICATION
                      if (status.trim().toLowerCase() == 'cancelled') ...[
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,

                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmRemoveCancelledApplication(
                                  context,
                                  applicationId,
                                  jobTitle,
                                  colors,
                                ),

                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 19,
                            ),

                            label: const Text('Remove'),

                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,

                              side: BorderSide(
                                color: Colors.redAccent.withValues(
                                  alpha: 0.4,
                                ),
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // UPDATE APPLICATION STATUS
                      if (status.trim().toLowerCase() != 'cancelled')
                        SizedBox(
                          width: double.infinity,
                          height: 48,

                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary.withValues(
                                alpha: colors.isDark ? 0.16 : 0.08,
                              ),

                              foregroundColor: colors.primary,
                              elevation: 0,

                              side: BorderSide(
                                color: colors.primary.withValues(alpha: 0.35),
                                width: 1.2,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),

                            onPressed: () {
                              _showStatusDialog(
                                context,
                                applicationId,
                                status,
                                colors,
                              );
                            },

                            icon: const Icon(
                              Icons.tune_rounded,
                              size: 18,
                            ),

                            label: const Text(
                              'Update Application Status',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // =====================================================
// APPLICANT IDENTITY CARD
// =====================================================

  Widget _applicantIdentityBox(
      BuildContext context,
      String userId,
      _AdminColors colors,
      ) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(userId),

      builder: (context, snapshot) {
        String displayName = 'Candidate';
        String email = '';
        String initials = 'C';

        final shortId = userId.length > 8
            ? userId.substring(0, 8)
            : userId;

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;

          final first =
          (data['firstName'] ?? '').toString().trim();

          final last =
          (data['lastName'] ?? '').toString().trim();

          final fullName = '$first $last'.trim();

          if (fullName.isNotEmpty) {
            displayName = fullName;

            if (first.isNotEmpty && last.isNotEmpty) {
              initials = '${first[0]}${last[0]}'.toUpperCase();
            } else if (first.isNotEmpty) {
              initials = first[0].toUpperCase();
            } else if (last.isNotEmpty) {
              initials = last[0].toUpperCase();
            }
          }

          email = (data['email'] ?? '').toString().trim();
        } else {
          displayName = 'Applicant #$shortId';

          if (userId.isNotEmpty) {
            initials = userId[0].toUpperCase();
          }
        }

        return Container(
          padding: const EdgeInsets.all(13),

          decoration: BoxDecoration(
            color: colors.primary.withValues(
              alpha: colors.isDark ? 0.08 : 0.04,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.cardBorder,
            ),
          ),

          child: Row(
            children: [
              // Applicant Avatar
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryDark,
                      colors.primaryAccent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),

                alignment: Alignment.center,

                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),

                          decoration: BoxDecoration(
                            color: colors.badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),

                          child: Text(
                            'APPLICANT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Applicant Email
                    if (email.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 13,
                            color: colors.textSecondary,
                          ),

                          const SizedBox(width: 5),

                          Flexible(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),
                    ],

                    // Applicant UID
                    Row(
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          size: 13,
                          color: colors.textSecondary,
                        ),

                        const SizedBox(width: 5),

                        Flexible(
                          child: Text(
                            'ID: $shortId...',
                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        const SizedBox(width: 5),

                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: userId),
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Applicant ID copied successfully.',
                                ),
                                backgroundColor: Color(0xFF10B981),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },

                          child: Padding(
                            padding: const EdgeInsets.all(3),

                            child: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // =====================================================
// RECRUITMENT PIPELINE STEPPER
// =====================================================

  Widget _buildApplicationPipeline(
      String status,
      _AdminColors colors,
      ) {
    int currentStep = 1;
    bool isRejected = false;

    final lower = status.trim().toLowerCase();

    if (lower == 'under review') {
      currentStep = 2;
    } else if (
    lower == 'shortlisted' ||
        lower.contains('interview')) {
      currentStep = 3;
    } else if (
    lower == 'hired' ||
        lower == 'accepted') {
      currentStep = 4;
    } else if (lower == 'rejected') {
      currentStep = 4;
      isRejected = true;
    }

    final steps = [
      'Applied',
      'Review',
      'Interview',
      isRejected ? 'Rejected' : 'Hired',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: colors.primary.withValues(
          alpha: colors.isDark ? 0.05 : 0.03,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.cardBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Recruitment Pipeline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: List.generate(
              steps.length,
                  (index) {
                final stepNumber = index + 1;

                final isCompleted =
                    stepNumber < currentStep;

                final isCurrent =
                    stepNumber == currentStep;

                final rejectedStep =
                    isRejected && stepNumber == 4;

                final stepColor = rejectedStep
                    ? Colors.redAccent
                    : (isCompleted || isCurrent)
                    ? colors.primary
                    : colors.textMuted;

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: index == 0
                                  ? Colors.transparent
                                  : isCompleted || isCurrent
                                  ? colors.primary
                                  : colors.divider,
                            ),
                          ),

                          Container(
                            width: 28,
                            height: 28,

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,

                              color: isCompleted || isCurrent
                                  ? stepColor
                                  : colors.cardBg,

                              border: Border.all(
                                color: stepColor,
                                width: 1.5,
                              ),
                            ),

                            child: Center(
                              child: rejectedStep
                                  ? const Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: Colors.white,
                              )
                                  : isCompleted
                                  ? const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Colors.white,
                              )
                                  : Text(
                                '$stepNumber',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.bold,
                                  color: isCurrent
                                      ? Colors.white
                                      : stepColor,
                                ),
                              ),
                            ),
                          ),

                          Expanded(
                            child: Container(
                              height: 2,
                              color: index == steps.length - 1
                                  ? Colors.transparent
                                  : isCompleted
                                  ? colors.primary
                                  : colors.divider,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Text(
                        steps[index],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: stepColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  // =====================================================
// UPDATE APPLICATION STATUS DIALOG
// =====================================================

  void _showStatusDialog(
      BuildContext context,
      String applicationId,
      String currentStatus,
      _AdminColors colors,
      ) {
    final statuses = [
      'Applied',
      'Under Review',
      'Shortlisted',
      'Interviewed',
      'Hired',
      'Rejected',
    ];

    if (currentStatus.trim().toLowerCase() == 'cancelled') {
      return;
    }

    String initialStatus = currentStatus;

    if (currentStatus == 'Interview') {
      initialStatus = 'Interviewed';
    }

    if (currentStatus == 'Accepted') {
      initialStatus = 'Hired';
    }

    if (!statuses.contains(initialStatus)) {
      initialStatus = 'Applied';
    }

    showDialog(
      context: context,

      builder: (dialogContext) {
        String selectedStatus = initialStatus;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.cardBg,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(
                  color: colors.cardBorder,
                  width: 1.2,
                ),
              ),

              title: Text(
                'Update Application Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),

              content: DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                isExpanded: true,
                dropdownColor: colors.cardBg,

                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                ),

                decoration: InputDecoration(
                  labelText: 'Application Status',

                  labelStyle: TextStyle(
                    color: colors.textSecondary,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.cardBorder,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: 1.5,
                    ),
                  ),
                ),

                items: statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),

                onChanged: isSaving
                    ? null
                    : (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),

              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),

                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colors.textSecondary,
                    ),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  onPressed: isSaving
                      ? null
                      : () async {
                    setDialogState(() {
                      isSaving = true;
                    });

                    try {
                      final firestore =
                          FirebaseFirestore.instance;

                      final ref = firestore
                          .collection('applications')
                          .doc(applicationId);

                      await firestore.runTransaction(
                            (transaction) async {
                          final snapshot =
                          await transaction.get(ref);

                          if (!snapshot.exists) {
                            throw Exception(
                              'Application not found.',
                            );
                          }

                          final data = snapshot.data();

                          final latestStatus =
                          (data?['status'] ?? '')
                              .toString()
                              .trim()
                              .toLowerCase();

                          if (latestStatus == 'cancelled') {
                            throw Exception(
                              'Cancelled applications cannot be updated.',
                            );
                          }

                          transaction.update(ref, {
                            'status': selectedStatus,
                            'updatedAt':
                            FieldValue.serverTimestamp(),
                          });
                        },
                      );

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);

                      if (!this.context.mounted) return;

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Application status updated successfully.',
                          ),
                          backgroundColor:
                          Color(0xFF10B981),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      setDialogState(() {
                        isSaving = false;
                      });

                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update status: $e',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },

                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // DATE FORMAT
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }
  Widget _viewAllButton({
    required _AdminColors colors,
    required bool showAll,
    required int totalCount,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            backgroundColor: colors.cardBg,
            side: BorderSide(
              color: colors.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(
            showAll
                ? Icons.keyboard_arrow_up_rounded
                : Icons.grid_view_rounded,
            size: 20,
          ),
          label: Text(
            showAll
                ? 'Show Less'
                : 'View All $totalCount $label',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // LOADING CARD
  // =====================================================

  Widget _loadingCard(_AdminColors colors) {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 1.2),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colors.primary,
        ),
      ),
    );
  }

  // =====================================================
  // ERROR CARD
  // =====================================================

  Widget _errorCard(String message, _AdminColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: colors.isDark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY CARD
  // =====================================================

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required _AdminColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 46,
            color: colors.isDark
                ? const Color(0xFF335242)
                : const Color(0xFFA7C1B3),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }


}