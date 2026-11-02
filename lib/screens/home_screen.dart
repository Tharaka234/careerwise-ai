import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isTabletOrDesktop = screenWidth >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'CareerWise',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
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
                  const Text(
                    'Welcome to CareerWise AI',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Your AI-powered career companion.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // QUICK ACTIONS PLACEHOLDER
                  // =================================================
                  _buildSectionTitle('Quick Actions'),

                  const SizedBox(height: 12),

                  _buildPlaceholderCard(
                    icon: Icons.dashboard_outlined,
                    title: 'Quick Actions',
                    subtitle:
                    'Career tools and shortcuts will appear here.',
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // FEATURED JOBS PLACEHOLDER
                  // =================================================
                  _buildSectionTitle('Featured Jobs'),

                  const SizedBox(height: 12),

                  _buildPlaceholderCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Featured Jobs',
                    subtitle:
                    'Recommended career opportunities will appear here.',
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // CAREER ADVISOR PLACEHOLDER
                  // =================================================
                  _buildSectionTitle('AI Career Advisor'),

                  const SizedBox(height: 12),

                  _buildPlaceholderCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Career Guidance',
                    subtitle:
                    'Personalized AI career guidance will appear here.',
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
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  // ============================================================
  // REUSABLE PLACEHOLDER CARD
  // ============================================================
  Widget _buildPlaceholderCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF475569),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
