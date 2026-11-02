
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_profile_screen.dart';
import 'notification_history_screen.dart';
import 'profile_screen.dart';
import 'career_advisor_screen.dart';


class _HomeColors {
  final bool isDark;

  const _HomeColors({required this.isDark});

  Color get pageBg =>
      isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);

  Color get cardBg =>
      isDark ? const Color(0xFF13231B) : Colors.white;

  Color get cardBorder =>
      isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);

  Color get cardSurface =>
      isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  Color get primary =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);

  Color get primaryAccent =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);

  Color get primaryDark =>
      isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  Color get textPrimary =>
      isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);

  Color get textSecondary =>
      isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);

  Color get textMuted =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  Color get divider =>
      isDark ? const Color(0xFF1C3426) : const Color(0xFFE5EFE9);
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Career Explorer';

    final initial = userName.isNotEmpty
        ? userName[0].toUpperCase()
        : 'C';

    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= 700;

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _HomeColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTabletOrDesktop ? 32 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PART 3 - PREMIUM HEADER
                      _buildHeader(context, initial, colors),

                      const SizedBox(height: 18),

                      // PART 4 - PERSONALIZED HERO BANNER
                      _buildHero(context, userName, colors),

                      const SizedBox(height: 28),

                      // QUICK ACTIONS PLACEHOLDER
                      _buildSectionTitle('Quick Actions', colors),

                      const SizedBox(height: 12),

                      _buildPlaceholderCard(
                        icon: Icons.dashboard_outlined,
                        title: 'Quick Actions',
                        subtitle:
                        'Career tools and shortcuts will appear here.',
                        colors: colors,
                      ),

                      const SizedBox(height: 28),

                      // FEATURED JOBS PLACEHOLDER
                      _buildSectionTitle('Featured Jobs', colors),

                      const SizedBox(height: 12),

                      _buildPlaceholderCard(
                        icon: Icons.work_outline_rounded,
                        title: 'Featured Jobs',
                        subtitle:
                        'Recommended career opportunities will appear here.',
                        colors: colors,
                      ),

                      const SizedBox(height: 28),

                      // AI CAREER ADVISOR PLACEHOLDER
                      _buildSectionTitle('AI Career Advisor', colors),

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
      },
    );
  }

  // ============================================================
  // PART 3 - PREMIUM HEADER
  // ============================================================

  Widget _buildHeader(
      BuildContext context,
      String initial,
      _HomeColors colors,
      ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
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
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 26,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CareerWise',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                'Your AI Career Companion',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // DARK / LIGHT THEME BUTTON
        _headerIconButton(
          colors: colors,
          tooltip: colors.isDark
              ? 'Switch to Light Theme'
              : 'Switch to Dark Theme',
          onPressed: () {
            AdminThemeManager.isDarkMode.value =
            !AdminThemeManager.isDarkMode.value;
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: colors.isDark
                ? const Icon(
              Icons.wb_sunny_rounded,
              key: ValueKey('sun'),
              color: Color(0xFFFDE047),
              size: 21,
            )
                : Icon(
              Icons.nightlight_round,
              key: const ValueKey('moon'),
              color: colors.primary,
              size: 21,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // NOTIFICATION HISTORY
        _headerIconButton(
          colors: colors,
          tooltip: 'Notification History',
          onPressed: () {
            _open(context, const NotificationHistoryScreen());
          },
          child: Icon(
            Icons.notifications_none_rounded,
            color: colors.textPrimary,
            size: 22,
          ),
        ),

        const SizedBox(width: 8),

        // PROFILE AVATAR
        InkWell(
          onTap: () {
            _open(context, const ProfileScreen());
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary,
                width: 1.5,
              ),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colors.primaryDark,
                    colors.primary,
                  ],
                ),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REUSABLE HEADER ICON BUTTON
  // ============================================================

  Widget _headerIconButton({
    required _HomeColors colors,
    required String tooltip,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.cardBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: child,
      ),
    );
  }

  // ============================================================
  // PART 4 - PREMIUM PERSONALIZED HERO BANNER
  // ============================================================

  static const String _heroImage =
      'assets/images/hero_student.jpg';

  Widget _buildHero(
      BuildContext context,
      String userName,
      _HomeColors colors,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        final bool isWide = width >= 700;

        final double bannerHeight = isWide ? 250 : 190;

        final double imageWidth = width * 0.36;

        return Container(
          width: double.infinity,
          height: bannerHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.cardBorder,
              width: 1.2,
            ),
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
                Color(0xFFE6F9EE),
                Color(0xFFD1FAE5),
                Color(0xFFA7F3D0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(
                  alpha: colors.isDark ? 0.30 : 0.15,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // STUDENT IMAGE WITH GRADIENT FADE
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: imageWidth,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
                      stops: [0.0, 0.4],
                    ).createShader(rect);
                  },
                  child: Image.asset(
                    _heroImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (
                        context,
                        error,
                        stackTrace,
                        ) {
                      return Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: isWide ? 110 : 80,
                          color: colors.primary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // PERSONALIZED WELCOME CONTENT
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 32 : 18,
                  16,
                  imageWidth * 0.85,
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hello, $userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isWide ? 17 : 14,
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
                          fontSize: isWide ? 34 : 22,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Take the next step towards your dream '
                          'career with CareerWise.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isWide ? 15 : 12,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),

                    SizedBox(
                      height: isWide ? 18 : 12,
                    ),

                    // EXPLORE CAREER PATHS BUTTON
                    GestureDetector(
                      onTap: () {
                        _open(
                          context,
                          const CareerAdvisorScreen(),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 20 : 14,
                          vertical: isWide ? 13 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colors.isDark
                                ? const [
                              Color(0xFF059669),
                              Color(0xFF047857),
                            ]
                                : const [
                              Color(0xFF059669),
                              Color(0xFF10B981),
                            ],
                          ),
                          borderRadius:
                          BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Flexible(
                              child: Text(
                                'Explore Career Paths',
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: TextStyle(
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
                              size: isWide ? 18 : 15,
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
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : colors.primary.withValues(alpha: 0.06),
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
