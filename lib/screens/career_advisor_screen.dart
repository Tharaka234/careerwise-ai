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