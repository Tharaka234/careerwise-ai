//Add Step 1: implement JobsColors dynamic theme color palette

import 'package:flutter/material.dart';

import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/services/job_service.dart';

import 'admin_profile_screen.dart';
import 'job_details_screen.dart';


class _JobsColors {
  final bool isDark;

  const _JobsColors({required this.isDark});

  // Backgrounds:
  // Light: Soft emerald-mint tint (#F0FDF4)
  // Dark: Deep luxurious obsidian forest green (#0A140F)
  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Inputs
  Color get inputBg => isDark ? const Color(0xFF0E1A14) : Colors.white;
  Color get inputBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFE2EFE7);

  // Brand / Emerald Accent Colors
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

//Add Step 2: setup JobsScreen state variables, controllers, and lifecycle handlers
class JobsScreen extends StatefulWidget {
  final String? career;

  const JobsScreen({
    super.key,
    this.career,
  });

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
final JobService _jobService = JobService();
final TextEditingController _searchController = TextEditingController();

String _searchQuery = '';
String _selectedType = 'All';
String _sortBy = 'Default';

final List<String> _jobTypes = [
'All',
'Full Time',
'Part Time',
'Internship',
'Contract',
'Remote',
];

bool get _isCareerFiltered =>
widget.career != null && widget.career!.trim().isNotEmpty;

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

//Add Step 3: implement multi-criteria job filtering, sorting logic, and details navigation
List<Job> _filterJobs(List<Job> jobs) {
final query = _searchQuery.trim().toLowerCase();

final filtered = jobs.where((job) {
final searchableText = [
job.title,
job.company,
job.location,
job.description,
job.jobType,
].join(' ').toLowerCase();

final matchesSearch =
query.isEmpty || searchableText.contains(query);

final type = job.jobType.trim().toLowerCase();

final matchesType = _selectedType == 'All' ||
type == _selectedType.toLowerCase() ||
(_selectedType == 'Full Time' &&
(type == 'full-time' || type == 'fulltime')) ||
(_selectedType == 'Part Time' &&
(type == 'part-time' || type == 'parttime')) ||
(_selectedType == 'Remote' &&
(type.contains('remote') ||
job.location.toLowerCase().contains('remote')));

return matchesSearch && matchesType;
}).toList();

if (_sortBy == 'Title A-Z') {
filtered.sort(
(a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
);
} else if (_sortBy == 'Company A-Z') {
filtered.sort(
(a, b) => a.company.toLowerCase().compareTo(b.company.toLowerCase()),
);
}

return filtered;
}

void _openJob(Job job) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => JobDetailsScreen(job: job),
),
);
}

//Add Step 4: implement interactive sort options modal bottom sheet

void _showSortOptions(_JobsColors colors) {
showModalBottomSheet(
context: context,
backgroundColor: Colors.transparent,
builder: (sheetContext) {
return SafeArea(
child: Container(
padding: const EdgeInsets.all(22),
decoration: BoxDecoration(
color: colors.cardBg,
borderRadius: const BorderRadius.vertical(
top: Radius.circular(28),
),
border: Border.all(color: colors.cardBorder),
),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 42,
height: 4,
decoration: BoxDecoration(
color: colors.cardBorder,
borderRadius: BorderRadius.circular(20),
),
),
),
const SizedBox(height: 22),
Text(
'Sort Opportunities',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.w800,
color: colors.textPrimary,
),
),
const SizedBox(height: 14),
...[
'Default',
'Title A-Z',
'Company A-Z',
].map((option) {
final selected = _sortBy == option;

return ListTile(
contentPadding: EdgeInsets.zero,
title: Text(
option,
style: TextStyle(
fontWeight: selected ? FontWeight.bold : FontWeight.w500,
color: selected ? colors.primary : colors.textPrimary,
),
),
trailing: selected
? Icon(
Icons.check_circle_rounded,
color: colors.primary,
)
: null,
onTap: () {
setState(() => _sortBy = option);
Navigator.pop(sheetContext);
},
);
}),
],
),
),
);
},
);
}