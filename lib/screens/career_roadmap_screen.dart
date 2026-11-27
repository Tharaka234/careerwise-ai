import 'package:flutter/material.dart';
import 'admin_profile_screen.dart';
import '../services/career_roadmap_service.dart';

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
  void initState() {
    super.initState();
    _loadOrGenerate();
  }
  Future<void> _loadOrGenerate() async {
    if (_generating) return;

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      await CareerRoadmapService.generateRoadmap(
        interviewId: widget.interviewId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

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
        body: _generating
            ? _loadingView()
            : Center(
          child: Text(
            _error ?? 'Career Roadmap Ready',
            textAlign: TextAlign.center,
            style: TextStyle(color: dark),
          ),
        ),
      ),
    );
  }
  Widget _loadingView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _softGreen,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: primary,
                size: 38,
              ),
            ),
            SizedBox(height: 26),
            CircularProgressIndicator(color: primary),
            SizedBox(height: 24),
            Text(
              'Preparing Your Career Roadmap',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'AI is analyzing your interview feedback and creating a personalized learning plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}