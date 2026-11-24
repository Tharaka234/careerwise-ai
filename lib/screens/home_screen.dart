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
}

