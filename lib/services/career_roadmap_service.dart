import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Handles AI-powered personalized career development roadmaps.
class CareerRoadmapService {
  CareerRoadmapService._();

  // Firebase Firestore instance.
  static final _db = FirebaseFirestore.instance;

  // Gemini API configuration.
  static const _apiKey =
  String.fromEnvironment('GEMINI_API_KEY');

  // Gemini model used for roadmap generation.
  static const _model = 'gemini-3.5-flash-lite';

  static String get _uid {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    return user.uid;
  }

  static DocumentReference<Map<String, dynamic>> _roadmapRef(
      String interviewId,
      ) {
    if (interviewId.trim().isEmpty ||
        interviewId.contains('/')) {
      throw Exception('Invalid interview ID.');
    }

    return _db
        .collection('users')
        .doc(_uid)
        .collection('career_roadmaps')
        .doc(interviewId);
  }
  static Future<Map<String, dynamic>> generateRoadmap({
    required String interviewId,
  }) async {
    final uid = _uid;
    final ref = _roadmapRef(interviewId);

    // Reuse an existing roadmap.
    final existing = await ref.get();

    if (existing.exists) {
      return {
        'id': existing.id,
        ...existing.data()!,
      };
    }

    // Read the original mock interview.
    final interviewDoc = await _db
        .collection('mock_interviews')
        .doc(interviewId)
        .get();

    // Validate interview existence.
    if (!interviewDoc.exists) {
      throw Exception('Interview not found.');
    }

    final interview = interviewDoc.data()!;

    // Validate interview ownership.
    if (interview['userId'] != uid) {
      throw Exception('Access denied.');
    }

    // Validate interview feedback.
    final feedback = interview['feedback'];

    if (feedback is! Map) {
      throw Exception('Interview feedback is missing.');
    }

    // Validate Gemini API configuration.
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key is missing.');
    }
    final prompt = '''
You are an AI career development coach for CareerWise.

Create a personalized 4-week learning roadmap based on
the applicant's mock interview feedback.

JOB INFORMATION:
Job: ${interview['jobTitle']}
Company: ${interview['company']}

INTERVIEW SCORE:
${interview['score']}

INTERVIEW FEEDBACK:
${jsonEncode(feedback)}

Return ONLY valid JSON with this structure:

{
  "title": "Personalized Career Development Roadmap",
  "overview": "Short personalized overview",
  "targetSkills": ["Skill 1", "Skill 2", "Skill 3"],
  "weeks": [
    {
      "week": 1,
      "title": "Learning focus",
      "description": "What to improve this week",
      "tasks": [
        {
          "title": "Specific learning task",
          "description": "How to complete the task"
        }
      ]
    }
  ]
}

RULES:
- Generate exactly 4 weeks.
- Generate exactly 3 tasks per week.
- Use the actual interview weaknesses and strengths.
- Make tasks realistic for university students.
- Include role-specific practical learning activities.
- Tasks should be achievable and measurable.
- Do not invent completed qualifications or experience.
- Do not treat the interview score as a hiring prediction.
- Do not include external URLs.
''';

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.4,
          'maxOutputTokens': 4096,
        }
      }),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      String errorMessage = 'Unknown Gemini API error';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map) {
          final error = errorData['error'];

          if (error is Map) {
            errorMessage =
                error['message']?.toString() ?? errorMessage;
          }
        }
      } catch (_) {
        errorMessage = 'Unable to read Gemini error response.';
      }

      debugPrint(
        'Gemini HTTP Status: ${response.statusCode}',
      );

      debugPrint('Gemini Error: $errorMessage');

      throw Exception(
        'Gemini API Error (${response.statusCode}): '
            '$errorMessage',
      );
    }

// Temporary code until Part 6.
    throw UnimplementedError(
      'AI response parsing is not implemented yet.',
    );
  }

}