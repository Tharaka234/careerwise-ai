import 'package:flutter/material.dart';
import 'admin_profile_screen.dart';

class CareerRoadmapScreen extends StatefulWidget {
  final String interviewId;

  const CareerRoadmapScreen({
    super.key,
    required this.interviewId,
  });

  @override
  State<CareerRoadmapScreen> createState() =>
      _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState
    extends State<CareerRoadmapScreen> {

  // Match the same palette and notifier used by HomeScreen.
  bool get _isDark => AdminThemeManager.isDarkMode.value;

  Color get primary =>
      _isDark ? Color(0xFF10B981) : Color(0xFF059669);

  Color get dark =>
      _isDark ? Color(0xFFF0FDF4) : Color(0xFF0F241B);

  Color get background =>
      _isDark ? Color(0xFF0A140F) : Color(0xFFF0FDF4);

  Color get muted =>
      _isDark ? Color(0xFFA7C1B3) : Color(0xFF4B6354);

  Color get border =>
      _isDark ? Color(0xFF1E382A) : Color(0xFFD1FAE5);

  Color get _cardBg =>
      _isDark ? Color(0xFF13231B) : Colors.white;

  Color get _surface =>
      _isDark ? Color(0xFF0F1E17) : Color(0xFFF8FAF9);

  Color get _softGreen =>
      _isDark ? Color(0xFF173D2D) : Color(0xFFEAF8F0);

  // Roadmap generation state.
  bool _generating = false;

  // Roadmap error state.
  String? _error;

  // Track tasks currently being updated.
  final Set<String> _updatingTasks = <String>{};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: dark),
          title: Text(
            'My Career Roadmap',
            style: TextStyle(
              color: dark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Career Development Roadmap',
            style: TextStyle(color: dark),
          ),
        ),
      ),
    );
  }
}