import 'package:flutter/material.dart';
import 'admin_profile_screen.dart';
import '../services/career_roadmap_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            : _error != null
            ? _errorView()
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: CareerRoadmapService.watchRoadmap(
            widget.interviewId,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _messageView(
                Icons.error_outline_rounded,
                'Unable to load roadmap',
                '${snapshot.error}',
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: primary,
                ),
              );
            }

            if (!snapshot.data!.exists) {
              return _messageView(
                Icons.route_outlined,
                'No roadmap available',
                'Generate your personalized roadmap.',
              );
            }

            return _roadmapView(
              snapshot.data!.data()!,
            );
          },
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
  Widget _errorView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 54,
            ),
            SizedBox(height: 16),
            Text(
              'Roadmap could not be loaded',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: muted,
                height: 1.5,
              ),
            ),
            SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _loadOrGenerate,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _messageView(
      IconData icon,
      String title,
      String message,
      ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primary,
              size: 50,
            ),
            SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              message,
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
  Widget _roadmapView(Map<String, dynamic> data) {
    final weeks = data['weeks'] is List
        ? data['weeks'] as List
        : <dynamic>[];

    final skills = data['targetSkills'] is List
        ? data['targetSkills'] as List
        : <dynamic>[];

    final completed =
        (data['completedTasks'] as num?)?.toInt() ?? 0;

    final total =
        (data['totalTasks'] as num?)?.toInt() ?? 12;

    final progress =
    ((data['progress'] as num?)?.toDouble() ?? 0.0)
        .clamp(0.0, 100.0)
        .toDouble();

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            _heroCard(data),
            SizedBox(height: 18),

            _progressCard(progress, completed, total),
            SizedBox(height: 28),

            _sectionTitle(
              'Skills to Master',
              Icons.psychology_alt_outlined,
            ),
            SizedBox(height: 12),

            _skillsCard(skills),
            SizedBox(height: 28),

            _sectionTitle(
              'Your Learning Journey',
              Icons.route_rounded,
            ),
            SizedBox(height: 7),

            Text(
              'Small steps today. Big career growth tomorrow.',
              style: TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 16),

            for (final rawWeek in weeks)
              if (rawWeek is Map)
                _weekCard(
                  Map<String, dynamic>.from(rawWeek),
                ),
          ],
        ),
      ),
    );
  }
  Widget _heroCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF066B50),
            Color(0xFF059669),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669)
                .withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            right: 80,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                '${data['title'] ?? 'Your Career Growth Plan'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${data['overview'] ?? ''}',
                style: const TextStyle(
                  color: Color(0xFFE5FFF3),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _heroTag(
                    Icons.calendar_today_outlined,
                    '4-week journey',
                  ),
                  _heroTag(
                    Icons.track_changes_rounded,
                    'Goal focused',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _heroTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  Widget _progressCard(
      double progress,
      int completed,
      int total,
      ) {
    return Container(
      padding: EdgeInsets.all(21),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: progress / 100,
              ),
              duration: Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: _softGreen,
                      color: primary,
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      color: dark,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 21),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress',
                  style: TextStyle(
                    color: dark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  '$completed of $total tasks completed',
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    progress >= 100
                        ? 'All done! 🎉'
                        : 'Keep growing 🌱',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _skillsCard(List skills) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: skills.isEmpty
          ? Text(
        'Your target skills will appear here.',
        style: TextStyle(color: muted),
      )
          : Wrap(
        spacing: 9,
        runSpacing: 9,
        children: skills.map((skill) => Chip(
          avatar: Icon(
            Icons.bolt_rounded,
            color: primary,
            size: 17,
          ),
          label: Text(skill.toString()),
          backgroundColor: _softGreen,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: TextStyle(
            color: dark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        )).toList(),
      ),
    );
  }
  Widget _weekCard(Map<String, dynamic> week) {
    final number = (week['week'] as num?)?.toInt() ?? 1;

    final rawTasks = week['tasks'] is List
        ? week['tasks'] as List
        : <dynamic>[];

    final tasks = rawTasks
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final done = tasks
        .where((task) => task['completed'] == true)
        .length;

    final ratio = tasks.isEmpty
        ? 0.0
        : done / tasks.length;

    final allDone =
        tasks.isNotEmpty && done == tasks.length;

    return Container(
      key: ValueKey('roadmap-week-$number'),
      margin: EdgeInsets.only(bottom: 14),
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('roadmap-expansion-$number'),
        initiallyExpanded: number == 1,
        shape: Border(),
        collapsedShape: Border(),
        tilePadding: EdgeInsets.fromLTRB(16, 13, 16, 13),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 18),

        leading: Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color: _softGreen,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: allDone
                ? Icon(
              Icons.check_circle_rounded,
              color: primary,
              size: 26,
            )
                : Text(
              '$number',
              style: TextStyle(
                color: primary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        title: Text(
          'WEEK $number',
          style: TextStyle(
            color: primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),

        subtitle: Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text(
            '${week['title'] ?? ''}',
            style: TextStyle(
              color: dark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$done/${tasks.length}',
              style: TextStyle(
                color: primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 3),
            Icon(
              Icons.expand_more_rounded,
              color: muted,
              size: 20,
            ),
          ],
        ),

        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: ratio,
              ),
              duration: Duration(milliseconds: 550),
              builder: (context, value, _) =>
                  LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: _softGreen,
                    color: primary,
                  ),
            ),
          ),

          SizedBox(height: 15),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${week['description'] ?? ''}',
              style: TextStyle(
                color: muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: 15),

          for (final task in tasks)
            _taskTile(task),
        ],
      ),
    );
  }
  Widget _taskTile(Map<String, dynamic> task) {
    final completed = task['completed'] == true;

    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      margin: EdgeInsets.only(bottom: 9),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: completed ? _softGreen : _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? primary.withValues(alpha: 0.35)
              : border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: completed ? primary : muted,
            size: 22,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${task['title'] ?? ''}',
                  style: TextStyle(
                    color: dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  '${task['description'] ?? ''}',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _softGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 21,
          ),
        ),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: dark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: _isDark ? 0.22 : 0.035,
          ),
          blurRadius: 15,
          offset: Offset(0, 5),
        ),
      ],
    );
  }
}