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

