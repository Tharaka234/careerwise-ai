
// Step 1: Imports and Dependencies
 
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_service.dart';
 

 // Step 2: Main Screen Widget Skeleton (StatefulWidget)

class CareerAdvisorScreen extends StatefulWidget {
  const CareerAdvisorScreen({super.key});

  @override
  State<CareerAdvisorScreen> createState() => _CareerAdvisorScreenState();
}

 
// Step 3: State Management, Form Controllers & Lifecycle
 
class _CareerAdvisorScreenState extends State<CareerAdvisorScreen> {
  // Form key and input text editing controllers
  final _formKey = GlobalKey<FormState>();
  final _education = TextEditingController();
  final _skills = TextEditingController();
  final _interests = TextEditingController();
  final _goals = TextEditingController();

  // AI Service instance
  final AIService _aiService = AIService();

  // State flags & response container
  bool isLoading = false;
  Map<String, dynamic>? result;

  @override
  void dispose() {
    _education.dispose();
    _skills.dispose();
    _interests.dispose();
    _goals.dispose();
    super.dispose();
  }

 
  // Step 4: AI Career Advice Generation & Persistence Logic
  
  Future<void> getCareerAdvice() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      result = null;
    });

    try {
      final education = _education.text.trim();
      final skills = _skills.text.trim();
      final interests = _interests.text.trim();
      final goals = _goals.text.trim();

      // Request recommendations from Gemini AI Service
      final aiResult = await _aiService.getCareerRecommendation(
        education: education,
        skills: skills,
        interests: interests,
        careerGoal: goals,
      );

      // Save recommendation to Firestore if user is authenticated
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _aiService.saveCareerRecommendation(
          userId: user.uid,
          education: education,
          skills: skills,
          interests: interests,
          careerGoal: goals,
          recommendation: jsonEncode(aiResult),
        );
      }

      if (!mounted) return;

      setState(() {
        result = aiResult;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      final message = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFCC3D52),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  
  // Step 5: Screen Scaffold & Theme Reactive Builder
   
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _AdvisorColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            title: Text(
              'CareerWise AI',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth > 700 ? 32.0 : 18.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding:
                      EdgeInsets.fromLTRB(horizontal, 16, horizontal, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHero(colors),
                          const SizedBox(height: 24),
                          _buildProgress(colors),
                          const SizedBox(height: 22),
                          _buildForm(constraints.maxWidth > 700, colors),
                          if (result != null) ...[
                            const SizedBox(height: 32),
                            _buildResults(colors),
                          ],
                          const SizedBox(height: 28),
                          Center(
                            child: Text(
                              'CAREERWISE  •  YOUR FUTURE, YOUR WAY',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textSecondary,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
 // Step 6: Premium Emerald Gradient Hero Banner
  Widget _buildHero(_AdvisorColors colors) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF044E36),
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -65,
            child: _decorativeCircle(190),
          ),
          Positioned(
            right: 85,
            bottom: -100,
            child: _decorativeCircle(170),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: Color(0xFFFFD98C),
                      ),
                      SizedBox(width: 7),
                      Text(
                        'AI-POWERED CAREER GUIDANCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Your future starts\nwith the right path.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Discover career opportunities that match your '
                  'skills, interests and ambitions.',
                  style: TextStyle(
                    color: Color(0xFFD1FAE5),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    _HeroFeature(
                      icon: Icons.explore_outlined,
                      label: 'Explore',
                    ),
                    SizedBox(width: 18),
                    _HeroFeature(
                      icon: Icons.psychology_outlined,
                      label: 'Discover',
                    ),
                    SizedBox(width: 18),
                    _HeroFeature(
                      icon: Icons.rocket_launch_outlined,
                      label: 'Grow',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Decorative ambient circles in Hero background
  Widget _decorativeCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
    );
  }

  // Step 7: Step-by-Step Progress Indicator
  Widget _buildProgress(_AdvisorColors colors) {
    return Row(
      children: [
        _progressItem('01', 'Your profile', true, colors),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: colors.cardBorder,
          ),
        ),
        _progressItem('02', 'AI analysis', false, colors),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: colors.cardBorder,
          ),
        ),
        _progressItem('03', 'Your results', false, colors),
      ],
    );
  }

  Widget _progressItem(
    String number,
    String label,
    bool active,
    _AdvisorColors colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? colors.primary : colors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? colors.primary : colors.cardBorder,
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: active ? colors.textPrimary : colors.textSecondary,
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
