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

  // Step 2: Implement Gemini API client with JSON generation and robust error handling
  Future<Map<String, dynamic>> _askGemini(String prompt) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'Gemini API key is missing. '
            'Check Android Studio Run Configuration.',
      );
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );

    http.Response response;

    try {
      response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey.trim(),
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json',
          },
        }),
      ).timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw Exception(
        'Gemini request timed out. '
            'Please check your internet connection and retry.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }

    if (response.statusCode != 200) {
      String apiMessage = 'Unknown API error';

      try {
        final errorJson = jsonDecode(response.body);
        apiMessage =
            errorJson['error']?['message']?.toString() ??
                apiMessage;
      } catch (_) {
        // Keep fallback message.
      }

      switch (response.statusCode) {
        case 400:
          throw Exception(
            'Invalid Gemini request: $apiMessage',
          );
        case 401:
        case 403:
          throw Exception(
            'Gemini API access denied: $apiMessage',
          );
        case 404:
          throw Exception(
            'Gemini model "$_model" was not found '
                'or is unavailable: $apiMessage',
          );
        case 429:
          throw Exception(
            'Gemini API quota exceeded. '
                'Please try again later. $apiMessage',
          );
        default:
          throw Exception(
            'Gemini API error (${response.statusCode}): '
                '$apiMessage',
          );
      }
    }

    dynamic responseJson;

    try {
      responseJson = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Gemini returned invalid response data.');
    }

    if (responseJson is! Map<String, dynamic>) {
      throw Exception('Unexpected Gemini response.');
    }

    final candidates = responseJson['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates.');
    }

    final candidate = candidates.first;

    if (candidate is! Map) {
      throw Exception('Invalid Gemini candidate.');
    }

    final content = candidate['content'];

    if (content is! Map || content['parts'] is! List) {
      throw Exception(
        'Gemini did not return text. '
            'Please try again.',
      );
    }

    final parts = content['parts'] as List;

    final text = parts
        .whereType<Map>()
        .map((part) => part['text']?.toString() ?? '')
        .join()
        .trim();

    if (text.isEmpty) {
      throw Exception('Gemini returned empty text.');
    }

    try {
      final decoded = jsonDecode(text);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }

      return decoded;
    } on FormatException {
      throw Exception(
        'Gemini returned an unexpected JSON format. '
            'Please retry.',
      );
    }
  }

  // Step 3: Implement countdown question timer with auto-tick and formatting
  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
    _timerDeadline = null;

    if (!_timerEnabled || _feedback != null) {
      return;
    }

    _timerDeadline = DateTime.now().add(
      const Duration(seconds: _questionDuration),
    );

    _questionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final deadline = _timerDeadline;

        if (deadline == null) {
          timer.cancel();
          return;
        }

        final milliseconds = deadline
            .difference(DateTime.now())
            .inMilliseconds;

        final remaining = milliseconds <= 0
            ? 0
            : (milliseconds / 1000).ceil();

        setState(() {
          _remainingSeconds = remaining;
          _timeExpired = remaining == 0;
        });

        if (remaining == 0) {
          timer.cancel();
        }
      },
    );
  }

  void _resetQuestionTimer() {
    _questionTimer?.cancel();
    _timerDeadline = null;

    setState(() {
      _remainingSeconds = _questionDuration;
      _timeExpired = false;
    });

    _startQuestionTimer();
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
    _timerDeadline = null;
  }

  void _toggleQuestionTimer(bool enabled) {
    _stopQuestionTimer();

    setState(() {
      _timerEnabled = enabled;
      _remainingSeconds = _questionDuration;
      _timeExpired = false;
    });

    if (enabled && !_loading && !_submitting) {
      _startQuestionTimer();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }
}
