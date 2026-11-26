
// Step 1: Imports and Dependencies & Dynamic Theme Palette Getters


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'career_roadmap_screen.dart';
import 'performance_comparison_screen.dart';
import 'admin_profile_screen.dart';

// Same theme notifier used across the application
bool get _isDark => AdminThemeManager.isDarkMode.value;
Color get _green => _isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
Color get _dark => _isDark ? const Color(0xFFF0FDF4) : const Color(0xFF123F35);
Color get _bg => _isDark ? const Color(0xFF0A140F) : const Color(0xFFF3F8F5);
Color get _muted => _isDark ? const Color(0xFFA7C1B3) : const Color(0xFF6B8177);
Color get _border => _isDark ? const Color(0xFF1E382A) : const Color(0xFFE1EBE5);
Color get _cardBg => _isDark ? const Color(0xFF13231B) : Colors.white;
Color get _softBg => _isDark ? const Color(0xFF18382A) : const Color(0xFFE8F7EE);
// Theme-aware score panel and navigation colors
Color get _backIcon => _isDark ? Colors.white : const Color(0xFF123F35);
Color get _scoreTrack => Colors.white24;


// Step 2: Main Screen Widget Skeleton (StatefulWidget)


class InterviewHistoryScreen extends StatefulWidget {
  const InterviewHistoryScreen({super.key});

  @override
  State<InterviewHistoryScreen> createState() =>
      _InterviewHistoryScreenState();
}

// Step 3: State Management, Search Controller & Active Filters


class _InterviewHistoryScreenState
    extends State<InterviewHistoryScreen> {
  // Search text editing controller
  final _search = TextEditingController();

  // Active score filter category ('All', '80+', '60–79', 'Below 60')
  String _filter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Step 4: Theme-Reactive Scaffold & AppBar with Info Dialog


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 86,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              // Premium Back Button
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _border,
                  ),
                ),
                child: IconButton(
                  tooltip: 'Back',
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _backIcon,
                    size: 19,
                  ),
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                ),
              ),

              const SizedBox(width: 14),

              // Page Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Interview History',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _dark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your AI practice journey',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Information action button for interview scores
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _softBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                tooltip: 'About interview scores',
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: _green,
                  size: 23,
                ),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('AI Practice Scores'),
                      content: const Text(
                        'Scores are AI-generated practice estimates '
                            'to help you improve your interview skills. '
                            'They do not predict hiring decisions.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),


        // Step 5: Firestore Real-Time StreamBuilder & Metrics Calculation


        body: user == null
            ? const Center(child: Text('Please sign in first.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('mock_interviews')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _message(
                Icons.error_outline,
                'Unable to load history',
                '${snapshot.error}',
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: _green),
              );
            }

            final all = snapshot.data!.docs.toList();

            // Sort interviews by newest first
            all.sort((a, b) {
              final at = a.data()['createdAt'];
              final bt = b.data()['createdAt'];
              final av = at is Timestamp
                  ? at.millisecondsSinceEpoch
                  : 0;
              final bv = bt is Timestamp
                  ? bt.millisecondsSinceEpoch
                  : 0;
              return bv.compareTo(av);
            });

            // Calculate average and best practice scores
            final scores = all
                .map((doc) => _score(doc.data()['score']))
                .toList();

            final average = scores.isEmpty
                ? 0
                : (scores.reduce((a, b) => a + b) / scores.length)
                .round();

            final best = scores.isEmpty
                ? 0
                : scores.reduce((a, b) => a > b ? a : b);


            // Step 6: Multi-Field Search Query & Threshold Filtering


            final query = _search.text.toLowerCase().trim();

            final filtered = all.where((doc) {
              final data = doc.data();
              final title =
              '${data['jobTitle'] ?? ''}'.toLowerCase();
              final company =
              '${data['company'] ?? ''}'.toLowerCase();
              final score = _score(data['score']);

              final matchesSearch =
                  title.contains(query) || company.contains(query);

              final matchesFilter = switch (_filter) {
                '80+' => score >= 80,
                '60–79' => score >= 60 && score < 80,
                'Below 60' => score < 60,
                _ => true,
              };

              return matchesSearch && matchesFilter;
            }).toList();

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    _stats(all.length, average, best),
                    const SizedBox(height: 25),
                    Text(
                      'Your Practice Sessions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review your performance and keep improving.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Search TextField
                    _buildSearchInput(),
                    const SizedBox(height: 14),

                    // Category Filter Chips
                    _buildFilterChips(),
                    const SizedBox(height: 18),

                    // History List or Empty State
                    if (filtered.isEmpty)
                      _emptyHistory(all.isEmpty)
                    else
                      ...filtered.map(
                            (doc) => _historyCard(
                          context,
                          doc.id,
                          doc.data(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Step 7: Emerald Gradient Hero Banner & Ambient Decor Widget


  Widget _header() {
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
            color: const Color(0xFF059669).withValues(alpha: 0.18),
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
            right: 100,
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
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Every interview\nmakes you better.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Track your practice, review AI feedback, '
                    'and prepare confidently for your next opportunity.',
                style: TextStyle(
                  color: Color(0xFFE5FFF3),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Container(
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
                child: const Text(
                  'AI Interview Practice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 8: Responsive Practice Performance Stats Grid Builder


  Widget _stats(int count, int average, int best) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        final cards = [
          _statCard(
            'Interviews',
            '$count',
            Icons.mic_outlined,
          ),
          _statCard(
            'Avg. Score',
            '$average',
            Icons.insights_outlined,
          ),
          _statCard(
            'Best Score',
            '$best',
            Icons.emoji_events_outlined,
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green, size: 24),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              color: _dark,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  // Step 9: Interactive Search Input & Category ChoiceChips


  Widget _buildSearchInput() {
    return TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search job title or company...',
        prefixIcon: Icon(
          Icons.search,
          color: _green,
        ),
        suffixIcon: _search.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _search.clear();
            setState(() {});
          },
        )
            : null,
        filled: true,
        fillColor: _cardBg,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _green,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', '80+', '60–79', 'Below 60']
            .map(
              (filter) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: _filter == filter,
              onSelected: (_) {
                setState(() => _filter = filter);
              },
              selectedColor: _softBg,
              backgroundColor: _cardBg,
              labelStyle: TextStyle(
                color: _filter == filter ? _dark : _muted,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: _border),
              showCheckmark: false,
            ),
          ),
        )
            .toList(),
      ),
    );
  }


  // Step 10: Interview History Session Card with Progress Indicator


  Widget _historyCard(
      BuildContext context,
      String interviewId,
      Map<String, dynamic> data,
      ) {
    final score = _score(data['score']);
    final date = _date(data['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InterviewHistoryDetailScreen(
                interviewId: interviewId,
                data: data,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _softBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: _green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['jobTitle'] ?? 'Interview'}',
                            style: TextStyle(
                              color: _dark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${data['company'] ?? 'Company'}',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            color: _green,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: _softBg,
                    color: _green,
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      'View Feedback',
                      style: TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 13,
                      color: _green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Step 11: Empty History State & Reusable Feedback Message Widget


  Widget _emptyHistory(bool noInterviews) {
    return _message(
      noInterviews
          ? Icons.history_edu_outlined
          : Icons.search_off_outlined,
      noInterviews ? 'No interviews yet' : 'No matching interviews',
      noInterviews
          ? 'Complete an AI mock interview to see your '
          'results here.'
          : 'Try another search or score filter.',
    );
  }

  Widget _message(
      IconData icon,
      String title,
      String description,
      ) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: _green),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}


// Step 12: Interview History Detail Screen Layout & Score Banner


class InterviewHistoryDetailScreen extends StatelessWidget {
  final String interviewId;
  final Map<String, dynamic> data;

  const InterviewHistoryDetailScreen({
    super.key,
    required this.interviewId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final rawFeedback = data['feedback'];
    final feedback = rawFeedback is Map
        ? Map<String, dynamic>.from(rawFeedback)
        : <String, dynamic>{};

    final questions = data['questions'] is List
        ? data['questions'] as List
        : <dynamic>[];

    final score = _score(data['score']);

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          foregroundColor: _backIcon,
          iconTheme: IconThemeData(color: _backIcon),
          title: Text(
            'Interview Results',
            style: TextStyle(
              color: _dark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                Container(
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
                        Color(0xFF10B981)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      )
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
                        right: 100,
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
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.emoji_events_outlined,
                                color: Colors.white, size: 25),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'YOUR PRACTICE SCORE',
                            style: TextStyle(
                              color: Color(0xFFE5FFF3),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$score / 100',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              color: const Color(0xFF6EE7B7),
                              backgroundColor: _scoreTrack,
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data['jobTitle'] ?? 'Interview'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['company'] ?? ''}',
                            style: const TextStyle(
                              color: Color(0xFFE5FFF3),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Text(
                              'AI Interview Practice',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),


                // Step 13: AI Performance Summary, Strengths & Q&A Cards


                _sectionCard(
                  'AI Performance Summary',
                  Icons.psychology_outlined,
                  child: Text(
                    '${feedback['summary'] ?? 'No summary available.'}',
                    style: TextStyle(
                      height: 1.65,
                      color: _dark,
                    ),
                  ),
                ),

                _feedbackCard(
                  'Your Strengths',
                  Icons.check_circle_outline,
                  feedback['strengths'],
                ),
                _feedbackCard(
                  'Areas to Improve',
                  Icons.trending_up,
                  feedback['improvements'],
                ),
                _feedbackCard(
                  'Preparation Tips',
                  Icons.lightbulb_outline,
                  feedback['tips'],
                ),

                const SizedBox(height: 14),
                Text(
                  'Questions & Your Answers',
                  style: TextStyle(
                    color: _dark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review your responses to prepare for your next interview.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 16),

                ...questions.asMap().entries.map((entry) {
                  final raw = entry.value;
                  final item = raw is Map
                      ? Map<String, dynamic>.from(raw)
                      : <String, dynamic>{};

                  return _sectionCard(
                    'Question ${entry.key + 1}',
                    Icons.chat_bubble_outline,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item['question'] ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _dark,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _softBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR ANSWER',
                                style: TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 9),
                              SelectableText(
                                '${item['answer'] ?? ''}',
                                style: TextStyle(
                                  height: 1.6,
                                  color: _dark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 14),


                // Step 14: Career Roadmap & Comparison Actions with Helpers


                if (data['originalInterviewId'] is String)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerformanceComparisonScreen(
                          originalInterviewId:
                          data['originalInterviewId'] as String,
                          reassessmentInterviewId: interviewId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.insights_rounded),
                    label: const Text('View Performance Comparison'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CareerRoadmapScreen(
                              interviewId: interviewId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text(
                        'Generate My Career Roadmap',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),

                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable feedback card
  Widget _feedbackCard(
      String title,
      IconData icon,
      dynamic items,
      ) {
    final values = items is List ? items : <dynamic>[];

    return _sectionCard(
      title,
      icon,
      child: values.isEmpty
          ? const Text('No feedback available.')
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: _green,
                  size: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$item',
                    style: TextStyle(
                      color: _dark,
                      height: 1.55,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // Reusable section container card
  Widget _sectionCard(
      String title,
      IconData icon, {
        required Widget child,
      }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// Data formatting and score clamping helper functions
int _score(dynamic value) {
  final number = value is num
      ? value.toInt()
      : int.tryParse('$value') ?? 0;

  return number.clamp(0, 100).toInt();
}

String _date(dynamic value) {
  if (value is! Timestamp) return 'Date unavailable';

  final date = value.toDate();

  String two(int n) => n.toString().padLeft(2, '0');

  return '${two(date.day)}/${two(date.month)}/${date.year}'
      '  •  ${two(date.hour)}:${two(date.minute)}';
}