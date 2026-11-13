// Step 1: setup AIMockInterviewScreen state, controllers, and Gemini configurations

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' show FontFeature;

import 'interview_history_screen.dart';

class AIMockInterviewScreen extends StatefulWidget {
  final String applicationId;
  final String jobTitle;
  final String company;

  const AIMockInterviewScreen({
    super.key,
    required this.applicationId,
    required this.jobTitle,
    required this.company,
  });

  @override
  State<AIMockInterviewScreen> createState() =>
      _AIMockInterviewScreenState();
}

class _AIMockInterviewScreenState extends State<AIMockInterviewScreen> {
  static const Color primary = Color(0xFF059669);
  static const Color background = Color(0xFFF0FDF4);
  static const Color dark = Color(0xFF10251D);

  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  // Use the same working model as Career Advisor.
  static const String _model = 'gemini-3.8-flash';

  final TextEditingController _answerController =
      TextEditingController();

  final List<String> _answers = [];

  List<String> _questions = [];
  Map<String, dynamic>? _feedback;

  int _currentIndex = 0;

  bool _loading = true;
  bool _submitting = false;
  bool _saving = false;

  // INTERVIEW TIMER VARIABLES


  static const int _questionDuration = 120; // 2 minutes

  Timer? _questionTimer;
  DateTime? _timerDeadline;

  int _remainingSeconds = _questionDuration;

  bool _timerEnabled = true;
  bool _timeExpired = false;

  String? _error;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _stopQuestionTimer(); // Stop interview timer
    _answerController.dispose();
    super.dispose();
  }
}
