import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey =
  String.fromEnvironment('GEMINI_API_KEY');

  static const String _model = 'gemini-2.5-flash';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
}