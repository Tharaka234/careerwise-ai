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



