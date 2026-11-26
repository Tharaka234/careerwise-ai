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

// Step 6: Client-Side Real-Time Search Filter Logic


List<QueryDocumentSnapshot> _filterRecommendations(
List<QueryDocumentSnapshot> docs) {
if (_searchQuery.isEmpty) return docs;

return docs.where((doc) {
final data = doc.data() as Map<String, dynamic>? ?? {};

final careerGoal = data['careerGoal']?.toString().toLowerCase() ?? '';
final skills = data['skills']?.toString().toLowerCase() ?? '';
final education = data['education']?.toString().toLowerCase() ?? '';
final interests = data['interests']?.toString().toLowerCase() ?? '';
final recommendation =
data['recommendation']?.toString().toLowerCase() ?? '';

return careerGoal.contains(_searchQuery) ||
skills.contains(_searchQuery) ||
education.contains(_searchQuery) ||
interests.contains(_searchQuery) ||
recommendation.contains(_searchQuery);
}).toList();
}

// Step 7: Emerald Gradient Header Banner & Header Button


Widget _buildHeader({
required _RecColors colors,
required int totalCount,
}) {
return Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: colors.isDark
? const [Color(0xFF03442C), Color(0xFF065F46), Color(0xFF047857)]
: const [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
),
borderRadius: const BorderRadius.only(
bottomLeft: Radius.circular(32),
bottomRight: Radius.circular(32),
),
boxShadow: [
BoxShadow(
color: colors.primary.withValues(alpha: colors.isDark ? 0.35 : 0.25),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: Stack(
children: [
Positioned(
right: -40,
top: -50,
child: Container(
width: 170,
height: 170,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.white.withValues(alpha: 0.08),
),
),
),
Positioned(
left: -50,
bottom: -60,
child: Container(
width: 160,
height: 160,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.white.withValues(alpha: 0.06),
),
),
),

SafeArea(
bottom: false,
child: Padding(
padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
_headerIconButton(
icon: Icons.arrow_back_ios_new_rounded,
onTap: () => Navigator.maybePop(context),
),
const Spacer(),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 7,
),
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.18),
borderRadius: BorderRadius.circular(30),
border: Border.all(
color: Colors.white.withValues(alpha: 0.26),
),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 8,
height: 8,
decoration: const BoxDecoration(
color: Color(0xFFC084FC),
shape: BoxShape.circle,
),
),
const SizedBox(width: 7),
Text(
'$totalCount AI Assessments',
style: const TextStyle(
color: Colors.white,
fontSize: 11.5,
fontWeight: FontWeight.bold,
letterSpacing: 0.3,
),
),
],
),
),
],
),

const SizedBox(height: 22),

Row(
children: [
Container(
width: 56,
height: 56,
decoration: BoxDecoration(
color: Colors.white.withValues(alpha: 0.18),
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: Colors.white.withValues(alpha: 0.28),
),
),
child: const Icon(
Icons.psychology_outlined,
color: Colors.white,
size: 32,
),
),
const SizedBox(width: 16),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'AI Recommendations',
style: TextStyle(
color: Colors.white,
fontSize: 23,
fontWeight: FontWeight.w800,
letterSpacing: -0.4,
),
),
SizedBox(height: 3),
Text(
'Platform AI career advice and guidance assessments',
style: TextStyle(
color: Color(0xFFE2FBEA),
fontSize: 13,
fontWeight: FontWeight.w500,
),
),
],
),
),
],
),
],
),
),
),
],
),
);
}

Widget _headerIconButton({
required IconData icon,
required VoidCallback onTap,
}) {
return Material(
color: Colors.white.withValues(alpha: 0.16),
borderRadius: BorderRadius.circular(14),
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(14),
child: Container(
width: 42,
height: 42,
alignment: Alignment.center,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: Colors.white.withValues(alpha: 0.22),
),
),
child: Icon(
icon,
color: Colors.white,
size: 19,
),
),
),
);
}

// Step 8: Search Bar and Quick Launch Advisor Banner


Widget _buildSearchAndAdvisorBanner(_RecColors colors) {
return Column(
children: [
// Search bar
TextField(
controller: _searchController,
onChanged: (val) {
setState(() {
_searchQuery = val.trim().toLowerCase();
});
},
style: TextStyle(
color: colors.textPrimary,
fontSize: 14.5,
),
decoration: InputDecoration(
hintText: 'Search assessments by goal, skills, or education...',
hintStyle: TextStyle(
color: colors.textMuted,
fontSize: 13.5,
),
prefixIcon: Icon(
Icons.search_rounded,
color: colors.primary,
size: 22,
),
suffixIcon: _searchQuery.isNotEmpty
? IconButton(
icon: Icon(
Icons.clear_rounded,
color: colors.textMuted,
size: 18,
),
onPressed: () {
_searchController.clear();
setState(() {
_searchQuery = '';
});
},
)
: null,
filled: true,
fillColor: colors.cardBg,
contentPadding: const EdgeInsets.symmetric(
horizontal: 18,
vertical: 16,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide(color: colors.cardBorder, width: 1.2),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide(color: colors.cardBorder, width: 1.2),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
borderSide: BorderSide(color: colors.primary, width: 1.8),
),
),
),

const SizedBox(height: 12),

// Hero CTA to launch Career Advisor
Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(
color: colors.cardBg,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: colors.cardBorder, width: 1.2),
),
child: Row(
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: const Color(0xFFC084FC).withValues(alpha: 0.16),
borderRadius: BorderRadius.circular(11),
),
child: const Icon(
Icons.auto_awesome_rounded,
color: Color(0xFF9333EA),
size: 20,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'AI Career Advisor Engine',
style: TextStyle(
fontSize: 13.5,
fontWeight: FontWeight.bold,
color: colors.textPrimary,
),
),
Text(
'Generate custom career roadmaps and skill assessments',
style: TextStyle(
fontSize: 11.5,
color: colors.textSecondary,
),
),
],
),
),
const SizedBox(width: 8),
ElevatedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const CareerAdvisorScreen(),
),
);
},
icon: const Icon(Icons.open_in_new_rounded, size: 14),
label: const Text('Open Advisor'),
style: ElevatedButton.styleFrom(
backgroundColor: colors.primary,
foregroundColor: Colors.white,
elevation: 0,
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 10,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
textStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
],
),
),
],
);
}

// Step 9: Recommendation JSON Parser & Plain Text Utilities


Map<String, dynamic>? _parseRecommendation(String raw) {
try {
final decoded = jsonDecode(raw);
if (decoded is Map<String, dynamic> &&
(decoded['careers'] is List ||
decoded['strengths'] is List ||
decoded['actionPlan'] is List)) {
return decoded;
}
} catch (_) {}
return null;
}

List<String> _stringList(dynamic value) {
if (value is! List) return const [];
return value
.map((e) => e.toString().trim())
.where((e) => e.isNotEmpty)
.toList();
}

List<Map<String, dynamic>> _mapList(dynamic value) {
if (value is! List) return const [];
return value
.whereType<Map>()
.map((e) => Map<String, dynamic>.from(e))
.toList();
}

/// Readable plain text (used by the Copy button).
String _plainRecommendation(String raw) {
final data = _parseRecommendation(raw);
if (data == null) return raw;

final out = StringBuffer();
final careers = _mapList(data['careers']);

for (var i = 0; i < careers.length; i++) {
final c = careers[i];
out.writeln('${i + 1}. ${c['title'] ?? ''}');
if ((c['whySuitable'] ?? '').toString().isNotEmpty) {
out.writeln('   ${c['whySuitable']}');
}
for (final entry in {
'Skills to develop': c['skillsToDevelop'],
'Learning areas': c['learningAreas'],
'Technologies': c['technologies'],
}.entries) {
final items = _stringList(entry.value);
if (items.isNotEmpty) out.writeln('   ${entry.key}: ${items.join(', ')}');
}
out.writeln();
}

final strengths = _stringList(data['strengths']);
if (strengths.isNotEmpty) {
out.writeln('Strengths');
for (final item in strengths) {
out.writeln('- $item');
}
out.writeln();
}

final plan = _stringList(data['actionPlan']);
if (plan.isNotEmpty) {
out.writeln('Action plan');
for (var i = 0; i < plan.length; i++) {
out.writeln('${i + 1}. ${plan[i]}');
}
}

return out.toString().trim();
}





