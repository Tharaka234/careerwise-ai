// Step 1: Imports and Dependencies


import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_profile_screen.dart';
import 'career_advisor_screen.dart';

// Step 2: Dynamic Theme Color Palette (Premium Emerald Green Theme)


class _RecColors {
  final bool isDark;

  const _RecColors({required this.isDark});

  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Brand / Emerald Accents
  Color get primary => isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get primaryAccent => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get primaryDark => isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary => isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);
  Color get textSecondary => isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);
  Color get textMuted => isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Icon Boxes & Badges
  Color get iconBoxBg => isDark ? const Color(0x3310B981) : const Color(0x1F059669);
}

// Step 3: Main Screen Widget Skeleton (StatefulWidget)


class AdminRecommendationsScreen extends StatefulWidget {
  const AdminRecommendationsScreen({super.key});

  @override
  State<AdminRecommendationsScreen> createState() =>
      _AdminRecommendationsScreenState();
}

// Step 4: State Management, Search Controller & Document Expansion


class _AdminRecommendationsScreenState
    extends State<AdminRecommendationsScreen> {
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
final Set<String> _expandedDocIds = {};

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

// Step 5: Screen Scaffold & Theme-Reactive StreamBuilder


@override
Widget build(BuildContext context) {
return ValueListenableBuilder<bool>(
valueListenable: AdminThemeManager.isDarkMode,
builder: (context, isDark, _) {
final colors = _RecColors(isDark: isDark);

return Scaffold(
backgroundColor: colors.pageBg,
body: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('career_recommendations')
.orderBy('createdAt', descending: true)
.snapshots(),
builder: (context, snapshot) {
final allDocs = snapshot.data?.docs ?? [];
final filteredDocs = _filterRecommendations(allDocs);

return CustomScrollView(
physics: const BouncingScrollPhysics(),
slivers: [
SliverToBoxAdapter(
child: _buildHeader(
colors: colors,
totalCount: allDocs.length,
),
),

SliverPadding(
padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
sliver: SliverToBoxAdapter(
child: Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 820),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Search Bar & Launch Advisor Banner
_buildSearchAndAdvisorBanner(colors),

const SizedBox(height: 20),

// Content list
if (snapshot.connectionState ==
ConnectionState.waiting &&
!snapshot.hasData)
_loadingCard(colors)
else if (snapshot.hasError)
_errorCard(
'Error loading recommendations: ${snapshot.error}',
colors,
)
else if (filteredDocs.isEmpty)
_emptyCard(
title: _searchQuery.isEmpty
? 'No AI recommendations found'
: 'No matching recommendations',
subtitle: _searchQuery.isEmpty
? 'AI career advice assessments will appear here as users explore.'
: 'Try searching with a different career goal, skill or education.',
colors: colors,
)
else
ListView.separated(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
itemCount: filteredDocs.length,
separatorBuilder: (context, index) =>
const SizedBox(height: 16),
itemBuilder: (context, index) {
final doc = filteredDocs[index];
final data =
doc.data() as Map<String, dynamic>? ??
{};
return _recommendationCard(
docId: doc.id,
data: data,
colors: colors,
);
},
),
],
),
),
),
),
),
],
);
},
),
);
},
);
}


