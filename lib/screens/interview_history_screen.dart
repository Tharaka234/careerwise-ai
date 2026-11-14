// Step 1: Imports and Dependencies & Theme Palette Constants

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _green = Color(0xFF059669);
const _dark = Color(0xFF123F35);
const _bg = Color(0xFFF3F8F5);
const _muted = Color(0xFF6B8177);
const _border = Color(0xFFE1EBE5);

// Step 2: create InterviewHistoryScreen StatefulWidget skeleton
class InterviewHistoryScreen extends StatefulWidget {
  const InterviewHistoryScreen({super.key});

  @override
  State<InterviewHistoryScreen> createState() =>
      _InterviewHistoryScreenState();
}
