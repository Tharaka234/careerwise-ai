  //Imports and Class Skeleton
  import 'dart:convert';

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';

  import '../services/ai_service.dart';

  class CareerAdvisorScreen extends StatefulWidget {
    const CareerAdvisorScreen({super.key});

    @override
      State<CareerAdvisorScreen> createState() =>
        _CareerAdvisorScreenState();
  }

 class _CareerAdvisorScreenState extends State<CareerAdvisorScreen> {
   static const Color navy = Color(0xFF172554);
   static const Color primary = Color(0xFF5267E8);
   static const Color violet = Color(0xFF8664E9);
   static const Color background = Color(0xFFF5F7FC);
   static const Color muted = Color(0xFF78839A);
   static const Color darkText = Color(0xFF202B45);

   //State Variables and Lifecycle Methods
   final _formKey = GlobalKey<FormState>();
   final _education = TextEditingController();
   final _skills = TextEditingController();
   final _interests = TextEditingController();
   final _goals = TextEditingController();

   final AIService _aiService = AIService();

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

// Add AI Logic & Form Validation
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

       final aiResult = await _aiService.getCareerRecommendation(
         education: education,
         skills: skills,
         interests: interests,
         careerGoal: goals,
       );

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
