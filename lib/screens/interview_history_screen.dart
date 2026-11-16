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
// Step 3: State Management, Search Controller & Filters
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


  // Step 4: Screen Scaffold & Custom AppBar with Practice Info Dialog
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFD8EDE3),
                ),
              ),
              child: IconButton(
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF066B50),
                  size: 19,
                ),
                onPressed: () {
                  Navigator.maybePop(context);
                },
              ),
            ),

            const SizedBox(width: 14),

            // Page Title and Subtitle
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Interview History',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF123F35),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your AI practice journey',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF6B8177),
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
              color: const Color(0xFFD8F5E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: 'About interview scores',
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF059669),
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
                  return const Center(
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
                    : (scores.reduce((a, b) => a + b) / scores.length).round();

                final best = scores.isEmpty
                    ? 0
                    : scores.reduce((a, b) => a > b ? a : b);

                final query = _search.text.toLowerCase().trim();

                // Multi-criteria filter: search query + score threshold
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
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        _header(),
                        const SizedBox(height: 20),
                        _stats(all.length, average, best),
                        const SizedBox(height: 25),
                        const Text(
                          'Your Practice Sessions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Review your performance and keep improving.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Search Input
                        _buildSearchInput(),
                        const SizedBox(height: 14),

                        // Score Category Filter Chips
                        _buildFilterChips(),
                        const SizedBox(height: 18),

                        // History List or Empty View
                        if (filtered.isEmpty)
                          _emptyHistory(all.isEmpty)
                        else
                          ...filtered.map(
                            (doc) => _historyCard(
                              context,
                              doc.data(),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  // Step 6: Implement emerald gradient hero banner and responsive stats summary cards
  Widget _header() {
    return Container(
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
                  color: Colors.white.withValues(alpha: 0.16),
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
              if (i != cards.length - 1)
                const SizedBox(width: 10),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _green, size: 24),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: _dark,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Step 7: Implement interactive search input and score category filter chips
  Widget _buildSearchInput() {
    return TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search job title or company...',
        prefixIcon: const Icon(
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
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
                  selectedColor: const Color(0xFFD8F5E5),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _filter == filter ? _dark : _muted,
                    fontWeight: FontWeight.w600,
                  ),
                  side: const BorderSide(color: _border),
                  showCheckmark: false,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}



