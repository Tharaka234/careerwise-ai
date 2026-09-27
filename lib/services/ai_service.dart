import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AIService {
// ==========================================================
// ⚠Run API Key :
// flutter run --dart-define=GEMINI_API_KEY=AIzaSy...
// ==========================================================
static const String _apiKey =
String.fromEnvironment('GEMINI_API_KEY');

static const String _model = 'gemini-2.5-flash';

static const String _baseUrl =
'https://generativelanguage.googleapis.com/v1beta/models';
