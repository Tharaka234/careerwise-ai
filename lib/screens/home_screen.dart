import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/services/job_service.dart';

import 'admin_profile_screen.dart';
import 'job_details_screen.dart';
import 'jobs_screen.dart';
import 'career_advisor_screen.dart';
import 'career_history_screen.dart';
import 'my_applications_screen.dart';
import 'profile_screen.dart';
import 'notification_history_screen.dart';
import 'interview_history_screen.dart';

// DYNAMIC THEME COLOR PALETTE (PREMIUM GREEN THEME)

class _HomeColors {
  final bool isDark;

  const _HomeColors({required this.isDark});

  // Backgrounds:
  // Light: Soft emerald-mint tint (#F0FDF4)
  // Dark: Deep luxurious obsidian forest green (#0A140F)
  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Brand / Emerald Accent Colors
  Color get primary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get primaryAccent => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get primaryDark => isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary => isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);
  Color get textSecondary => isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);
  Color get textMuted => isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Dividers & Badges
  Color get divider => isDark ? const Color(0xFF1C3426) : const Color(0xFFE5EFE9);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Career Explorer';

    final String initial =
        userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _HomeColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          bottomNavigationBar: _buildBottomNav(context, colors),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width >= 700 ? 32 : 16,
                14,
                MediaQuery.of(context).size.width >= 700 ? 32 : 16,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, initial, colors),
                      const SizedBox(height: 18),
                      _buildHero(context, userName, colors),
                      const SizedBox(height: 26),
                      _buildSectionTitle(
                        'Quick Actions',
                        colors,
                      ),
                      const SizedBox(height: 14),

// Quick Actions
                      _buildQuickActions(context, colors),

                      const SizedBox(height: 12),

// Interview History - Full Width Card
                      _buildInterviewHistoryCard(context, colors),

                      const SizedBox(height: 28),

// Featured Jobs
                      _buildFeaturedHeader(context, colors),

                      const SizedBox(height: 14),
                      _buildFeaturedJobs(colors),

                      const SizedBox(height: 22),
                      _buildCtaBanner(context, colors),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Add HEADER

  Widget _buildHeader(
    BuildContext context,
    String initial,
    _HomeColors colors,
  ) {
    return Row(
      children: [
        // App Logo Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors.isDark
                  ? const [Color(0xFF047857), Color(0xFF059669)]
                  : const [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CareerWise',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your AI Career Companion',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // 1. Theme Toggle Button (Sun / Moon)
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                    .withValues(alpha: colors.isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            tooltip: colors.isDark
                ? 'Switch to Light Theme'
                : 'Switch to Dark Theme',
            padding: EdgeInsets.zero,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: child.key == const ValueKey('dark_icon')
                      ? Tween<double>(begin: 0.75, end: 1.0).animate(animation)
                      : Tween<double>(begin: 0.25, end: 0.0).animate(animation),
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: colors.isDark
                  ? const Icon(
                      Icons.wb_sunny_rounded,
                      key: ValueKey('dark_icon'),
                      color: Color(0xFFFDE047),
                      size: 21,
                    )
                  : Icon(
                      Icons.nightlight_round,
                      key: const ValueKey('light_icon'),
                      color: colors.primary,
                      size: 21,
                    ),
            ),
            onPressed: () {
              AdminThemeManager.isDarkMode.value =
                  !AdminThemeManager.isDarkMode.value;
            },
          ),
        ),

        const SizedBox(width: 10),

        // 2. Notification History Button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                    .withValues(alpha: colors.isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _open(context, const NotificationHistoryScreen()),
            tooltip: 'Notification history',
            icon: Icon(
              Icons.notifications_none_rounded,
              color: colors.textPrimary,
              size: 22,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // 3. Profile Avatar
        GestureDetector(
          onTap: () => _open(context, const ProfileScreen()),
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 1.5),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: colors.isDark
                      ? const [Color(0xFF047857), Color(0xFF059669)]
                      : const [Color(0xFF059669), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // HERO BANNER (LUSH EMERALD MINT GRADIENT)

  static const String _heroImage = 'assets/images/hero_student.jpg';

  Widget _buildHero(
    BuildContext context,
    String userName,
    _HomeColors colors,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final bool wide = w >= 700;

        final double height = wide ? 250 : 190;
        final double imageWidth = wide ? w * 0.36 : w * 0.36;

        return Container(
          height: height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.cardBorder, width: 1.2),
            gradient: LinearGradient(
              colors: colors.isDark
                  ? const [
                      Color(0xFF064E3B),
                      Color(0xFF047857),
                      Color(0xFF065F46),
                    ]
                  : const [
                      Color(0xFFE6F9EE),
                      Color(0xFFD1FAE5),
                      Color(0xFFA7F3D0),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: colors.isDark ? 0.3 : 0.15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Image fills the right side and fades smoothly
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: imageWidth,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.4],
                  ).createShader(rect),
                  child: Image.asset(
                    _heroImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: wide ? 110 : 80,
                        color: colors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),

              // Text & Call to Action
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 32 : 18,
                  16,
                  imageWidth * 0.85,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hello, $userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: wide ? 17 : 14,
                        fontWeight: FontWeight.w600,
                        color: colors.isDark
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Good to see you 👋',
                        style: TextStyle(
                          fontSize: wide ? 34 : 22,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Take the next step towards your dream career with CareerWise.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: wide ? 15 : 12,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: wide ? 18 : 12),
                    GestureDetector(
                      onTap: () => _open(context, const CareerAdvisorScreen()),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 20 : 14,
                          vertical: wide ? 13 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors.isDark
                                ? const [Color(0xFF059669), Color(0xFF047857)]
                                : const [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Explore Career Paths',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: wide ? 18 : 15,
                            ),
                          ],
                        ),
                      ),
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

  // SECTION TITLE

  Widget _buildSectionTitle(
    String title,
    _HomeColors colors, {
    String? trailing,
  }) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.primaryAccent],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trailing,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: colors.textSecondary,
          ),
        ],
      ],
    );
  }


  // QUICK ACTIONS

  Widget _buildQuickActions(BuildContext context, _HomeColors colors) {
    final items = <Widget>[
      _quickAction(
        context,
        icon: Icons.smart_toy_outlined,
        title: 'AI Career Advisor',
        subtitle: 'Get personalized career recommendations',
        color: colors.isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
        page: const CareerAdvisorScreen(),
        colors: colors,
      ),
      _quickAction(
        context,
        icon: Icons.work_outline_rounded,
        title: 'Browse Jobs',
        subtitle: 'Find opportunities that match you',
        color: colors.isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1),
        page: const JobsScreen(),
        colors: colors,
      ),
      _quickAction(
        context,
        icon: Icons.history_rounded,
        title: 'Career History',
        subtitle: 'View your past recommendations',
        color: colors.isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
        page: const CareerHistoryScreen(),
        colors: colors,
      ),
      _quickAction(
        context,
        icon: Icons.description_outlined,
        title: 'My Applications',
        subtitle: 'Track your job applications',
        color: colors.isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
        page: const MyApplicationsScreen(),
        colors: colors,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth < 600 ? 2 : 4;
        final double gap = constraints.maxWidth >= 700 ? 14 : 10;

        final rows = <Widget>[];
        for (int i = 0; i < items.length; i += columns) {
          final rowItems = items.skip(i).take(columns).toList();
          final children = <Widget>[];
          for (int j = 0; j < rowItems.length; j++) {
            if (j > 0) children.add(SizedBox(width: gap));
            children.add(Expanded(child: rowItems[j]));
          }
          if (i > 0) rows.add(SizedBox(height: gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }

