import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CareerRoadmapService {
  CareerRoadmapService._();

  static final _db = FirebaseFirestore.instance;

  static const _apiKey =
  String.fromEnvironment('GEMINI_API_KEY');

  // Use a model confirmed to work with your Gemini API key.
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
      return {'id': existing.id, ...existing.data()!};
    }

    // Read the original interview.
    final interviewDoc = await _db
        .collection('mock_interviews')
        .doc(interviewId)
        .get();

    if (!interviewDoc.exists) {
      throw Exception('Interview not found.');
    }

    final interview = interviewDoc.data()!;

    if (interview['userId'] != uid) {
      throw Exception('Access denied.');
    }

    final feedback = interview['feedback'];
    if (feedback is! Map) {
      throw Exception('Interview feedback is missing.');
    }

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

    final apiData =
    jsonDecode(response.body) as Map<String, dynamic>;

    final candidates = apiData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('AI returned no roadmap.');
    }

    final parts = candidates.first['content']['parts'] as List;

    final responseText = parts
        .map((part) => part['text']?.toString() ?? '')
        .join()
        .trim();

    final roadmap =
    jsonDecode(responseText) as Map<String, dynamic>;

    final rawWeeks = roadmap['weeks'];

    if (rawWeeks is! List || rawWeeks.length != 4) {
      throw Exception('AI must generate exactly 4 weeks.');
    }

    final weeks = <Map<String, dynamic>>[];

    for (var i = 0; i < rawWeeks.length; i++) {
      final week = Map<String, dynamic>.from(rawWeeks[i]);
      final rawTasks = week['tasks'];

      if (rawTasks is! List || rawTasks.length != 3) {
        throw Exception('Each week must have exactly 3 tasks.');
      }

      final tasks = <Map<String, dynamic>>[];

      for (var j = 0; j < rawTasks.length; j++) {
        final task = Map<String, dynamic>.from(rawTasks[j]);

        final title = task['title']?.toString().trim() ?? '';
        final description =
            task['description']?.toString().trim() ?? '';

        if (title.isEmpty || description.isEmpty) {
          throw Exception('AI generated an incomplete task.');
        }

        tasks.add({
          'id': 'week_${i + 1}_task_${j + 1}',
          'title': title,
          'description': description,
          'completed': false,
        });
      }

      weeks.add({
        'week': i + 1,
        'title': week['title']?.toString() ?? '',
        'description':
        week['description']?.toString() ?? '',
        'tasks': tasks,
      });
    }

    final targetSkills = roadmap['targetSkills'];
    if (targetSkills is! List) {
      throw Exception('Invalid target skills.');
    }

    final result = <String, dynamic>{
      'userId': uid,
      'interviewId': interviewId,
      'applicationId': interview['applicationId'] ?? '',
      'jobTitle': interview['jobTitle'] ?? '',
      'company': interview['company'] ?? '',
      'interviewScore': interview['score'] ?? 0,
      'title': roadmap['title']?.toString() ??
          'Your Career Roadmap',
      'overview': roadmap['overview']?.toString() ?? '',
      'targetSkills':
      targetSkills.map((e) => e.toString()).toList(),
      'weeks': weeks,
      'totalTasks': 12,
      'completedTasks': 0,
      'progress': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Transaction prevents overwriting a roadmap created
    // by another concurrent request.
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, result);
      }
    });

    final saved = await ref.get();
    return {'id': saved.id, ...saved.data()!};
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>>
  watchRoadmap(String interviewId) {
    return _roadmapRef(interviewId).snapshots();
  }

  static Future<void> updateTask({
    required String interviewId,
    required String taskId,
    required bool completed,
  }) async {
    final ref = _roadmapRef(interviewId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        throw Exception('Roadmap not found.');
      }

      final data = snapshot.data()!;
      if (data['userId'] != _uid) {
        throw Exception('Access denied.');
      }

      final weeks = (data['weeks'] as List)
          .map((week) => Map<String, dynamic>.from(week))
          .toList();

      var found = false;
      var completedCount = 0;
      var totalCount = 0;

      for (final week in weeks) {
        final tasks = (week['tasks'] as List)
            .map((task) => Map<String, dynamic>.from(task))
            .toList();

        for (final task in tasks) {
          if (task['id'] == taskId) {
            task['completed'] = completed;
            found = true;
          }

          totalCount++;
          if (task['completed'] == true) {
            completedCount++;
          }
        }

        week['tasks'] = tasks;
      }

      if (!found) {
        throw Exception('Task not found.');
      }

      final progress = totalCount == 0
          ? 0
          : ((completedCount / totalCount) * 100).round();

      transaction.update(ref, {
        'weeks': weeks,
        'completedTasks': completedCount,
        'totalTasks': totalCount,
        'progress': progress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
