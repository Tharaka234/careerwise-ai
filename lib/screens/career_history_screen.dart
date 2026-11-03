//Step 1: implement CareerHistoryColors design system with dark and light themes
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_profile_screen.dart';

// EMERALD GREEN THEME DESIGN SYSTEM & STYLES

class CareerHistoryColors {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color tagBg;
  final Color tagBorder;
  final Color searchFill;
  final Color iconBg;

  CareerHistoryColors({required this.isDark})
      : pageBg = isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4),
        cardBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        cardBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        textPrimary = isDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        primary = const Color(0xFF059669),
        primaryDark = const Color(0xFF044E36),
        accent = const Color(0xFF10B981),
        tagBg = isDark ? const Color(0xFF0E2319) : const Color(0xFFECFDF5),
        tagBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFA7F3D0),
        searchFill = isDark ? const Color(0xFF0A1F16) : Colors.white,
        iconBg = isDark ? const Color(0xFF0E2319) : const Color(0xFFECFDF5);
}