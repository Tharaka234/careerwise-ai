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
}