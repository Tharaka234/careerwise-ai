//Add Step 1: setup JobDetailsScreen state and JobDetailsColors theme palette

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:careerwise_sample/model/job.dart';
import 'admin_profile_screen.dart';

class _JobDetailsColors {
  final bool isDark;
  final Color background;
  final Color cardBg;
  final Color dark;
  final Color muted;
  final Color border;
  final Color primary;
  final Color deepGreen;
  final Color lightGreen;

  const _JobDetailsColors({
    required this.isDark,
    required this.background,
    required this.cardBg,
    required this.dark,
    required this.muted,
    required this.border,
    required this.primary,
    required this.deepGreen,
    required this.lightGreen,
  });

  factory _JobDetailsColors.of(bool isDark) {
    if (isDark) {
      return const _JobDetailsColors(
        isDark: true,
        background: Color(0xFF0A140F),
        cardBg: Color(0xFF13231B),
        dark: Color(0xFFF1F5F9),
        muted: Color(0xFF94A3B8),
        border: Color(0xFF1E3A2B),
        primary: Color(0xFF10B981),
        deepGreen: Color(0xFF064E3B),
        lightGreen: Color(0xFF34D399),
      );
    }
    return const _JobDetailsColors(
      isDark: false,
      background: Color(0xFFF0FDF4),
      cardBg: Colors.white,
      dark: Color(0xFF0F241B),
      muted: Color(0xFF4B6354),
      border: Color(0xFFD1FAE5),
      primary: Color(0xFF059669),
      deepGreen: Color(0xFF065F46),
      lightGreen: Color(0xFF10B981),
    );
  }
}

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
_JobDetailsColors _colors = _JobDetailsColors.of(false);

Color get primary => _colors.primary;
Color get deepGreen => _colors.deepGreen;
Color get lightGreen => _colors.lightGreen;
Color get background => _colors.background;
Color get dark => _colors.dark;
Color get muted => _colors.muted;
Color get border => _colors.border;
Color get cardBg => _colors.cardBg;

bool isApplying = false;
bool hasApplied = false;
bool isChecking = true;
String? statusError;

@override
void initState() {
super.initState();
_checkApplicationStatus();
}

//Add Step 2: implement Firestore application verification and submission logic

Future<void> _checkApplicationStatus() async {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
if (mounted) {
setState(() => isChecking = false);
}
return;
}

try {
final result = await FirebaseFirestore.instance
.collection('applications')
.where('userId', isEqualTo: user.uid)
.where('jobId', isEqualTo: widget.job.id)
.limit(1)
.get();

if (!mounted) return;

setState(() {
hasApplied = result.docs.isNotEmpty;
isChecking = false;
statusError = null;
});
} catch (e) {
debugPrint('Application check error: $e');

if (!mounted) return;

setState(() {
isChecking = false;
statusError = 'Unable to check your application status.';
});
}
}

Future<void> _applyForJob() async {
final user = FirebaseAuth.instance.currentUser;

if (user == null || isApplying || hasApplied) return;

setState(() => isApplying = true);

try {
final existing = await FirebaseFirestore.instance
.collection('applications')
.where('userId', isEqualTo: user.uid)
.where('jobId', isEqualTo: widget.job.id)
.limit(1)
.get();

if (!mounted) return;

if (existing.docs.isNotEmpty) {
setState(() {
hasApplied = true;
isApplying = false;
});

_showSnackBar('You have already applied for this job.');
return;
}

await FirebaseFirestore.instance
.collection('applications')
.add({
'userId': user.uid,
'jobId': widget.job.id,
'jobTitle': widget.job.title,
'company': widget.job.company,
'status': 'Applied',
'appliedAt': FieldValue.serverTimestamp(),
});

if (!mounted) return;

setState(() {
hasApplied = true;
isApplying = false;
});

_showSnackBar('Application submitted successfully!');
} catch (e) {
debugPrint('Apply job error: $e');

if (!mounted) return;

setState(() => isApplying = false);

_showSnackBar(
'Could not submit your application. Please try again.',
error: true,
);
}
}

void _showSnackBar(String message, {bool error = false}) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
behavior: SnackBarBehavior.floating,
backgroundColor:
error ? const Color(0xFFDC2626) : const Color(0xFF15803D),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
content: Row(
children: [
Icon(
error
? Icons.error_outline_rounded
: Icons.check_circle_outline_rounded,
color: Colors.white,
),
const SizedBox(width: 10),
Expanded(child: Text(message)),
],
),
),
);
}