
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

 
