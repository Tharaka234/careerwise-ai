import 'package:flutter/material.dart';

class _HomeColors {
  final bool isDark;

  const _HomeColors({required this.isDark});

  // Background colors
  Color get pageBg => isDark
      ? const Color(0xFF0A140F)
      : const Color(0xFFF0FDF4);

  Color get cardBg => isDark
      ? const Color(0xFF13231B)
      : Colors.white;

  Color get cardBorder => isDark
      ? const Color(0xFF1E382A)
      : const Color(0xFFD1FAE5);

  Color get cardSurface => isDark
      ? const Color(0xFF0F1E17)
      : const Color(0xFFF8FAF9);

  // Primary emerald colors
  Color get primary => isDark
      ? const Color(0xFF10B981)
      : const Color(0xFF059669);

  Color get primaryAccent => isDark
      ? const Color(0xFF34D399)
      : const Color(0xFF10B981);

  Color get primaryDark => isDark
      ? const Color(0xFF059669)
      : const Color(0xFF047857);

  // Text colors
  Color get textPrimary => isDark
      ? const Color(0xFFF0FDF4)
      : const Color(0xFF0F241B);

  Color get textSecondary => isDark
      ? const Color(0xFFA7C1B3)
      : const Color(0xFF4B6354);

  Color get textMuted => isDark
      ? const Color(0xFF6B7280)
      : const Color(0xFF94A3B8);

  // Dividers
  Color get divider => isDark
      ? const Color(0xFF1C3426)
      : const Color(0xFFE5EFE9);
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isTabletOrDesktop = screenWidth >= 700;

    // Part 2: Use light theme by default.
    // Part 3 will connect this to the shared theme manager.
    const bool isDark = false;

    final colors = _HomeColors(isDark: isDark);

    return Scaffold(
      backgroundColor: colors.pageBg,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: colors.cardBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'CareerWise',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
      ),

      // ========================================================
      // RESPONSIVE BODY
      // ========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTabletOrDesktop ? 32 : 16,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // WELCOME SECTION
                  // =================================================
                  Text(
                    'Welcome to CareerWise AI',
                    style: TextStyle(
                      fontSize: isTabletOrDesktop ? 30 : 26,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your AI-powered career companion.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // QUICK ACTIONS
                  // =================================================
                  _buildSectionTitle(
                    'Quick Actions',
                    colors,
                  ),

                  const SizedBox(height: 12),

                  _buildPlaceholderCard(
                    icon: Icons.dashboard_outlined,
                    title: 'Quick Actions',
                    subtitle:
                    'Career tools and shortcuts will appear here.',
                    colors: colors,
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // FEATURED JOBS
                  // =================================================
                  _buildSectionTitle(
                    'Featured Jobs',
                    colors,
                  ),

                  const SizedBox(height: 12),

                  _buildPlaceholderCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Featured Jobs',
                    subtitle:
                    'Recommended career opportunities will appear here.',
                    colors: colors,
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // AI CAREER ADVISOR
                  // =================================================
                  _buildSectionTitle(
                    'AI Career Advisor',
                    colors,
                  ),

                  const SizedBox(height: 12),

                  _buildPlaceholderCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Career Guidance',
                    subtitle:
                    'Personalized AI career guidance will appear here.',
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
  Widget _buildSectionTitle(
      String title,
      _HomeColors colors,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary,
                colors.primaryAccent,
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REUSABLE PREMIUM CARD
  // ============================================================
  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required _HomeColors colors,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}
