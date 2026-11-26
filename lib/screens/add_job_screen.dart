// Step 1: Imports and Dependencies


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';
import 'admin_profile_screen.dart';

// Step 2: Dynamic Theme Color Palette (Premium Emerald Green Theme)


class _AddJobColors {
  final bool isDark;

  const _AddJobColors({required this.isDark});

  // Backgrounds:
  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get appBarBg => isDark ? const Color(0xFF0E1B15) : Colors.white;
  Color get appBarBorder => isDark ? const Color(0xFF1A3325) : const Color(0xFFE2EFE7);

  // Inputs
  Color get inputBg => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF7FAF8);
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

// Step 3: Main Screen Widget Skeleton (StatefulWidget)


class AddJobScreen extends StatefulWidget {
  final String? jobId;
  final Map<String, dynamic>? existingJob;

  const AddJobScreen({
    super.key,
    this.jobId,
    this.existingJob,
  });

  bool get isEditMode => jobId != null && existingJob != null;

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

// Step 4: State Management, Form Controllers & Lifecycle


class _AddJobScreenState extends State<AddJobScreen> {
final _formKey = GlobalKey<FormState>();

final titleController = TextEditingController();
final companyController = TextEditingController();
final locationController = TextEditingController();
final descriptionController = TextEditingController();
final salaryController = TextEditingController();

String selectedJobType = 'Full Time';
String selectedCategory = JobCategories.fallback;
bool isLoading = false;

@override
void initState() {
super.initState();

if (widget.isEditMode) {
final job = widget.existingJob!;

titleController.text = job['title']?.toString() ?? '';
companyController.text = job['company']?.toString() ?? '';
locationController.text = job['location']?.toString() ?? '';
descriptionController.text = job['description']?.toString() ?? '';
salaryController.text = job['salary']?.toString() ?? '';

final jobType = job['jobType']?.toString();

if (jobType != null &&
[
'Full Time',
'Part Time',
'Internship',
'Contract',
].contains(jobType)) {
selectedJobType = jobType;
}

final category = job['category']?.toString();

if (category != null && JobCategories.all.contains(category)) {
selectedCategory = category;
}
}
}

@override
void dispose() {
titleController.dispose();
companyController.dispose();
locationController.dispose();
descriptionController.dispose();
salaryController.dispose();
super.dispose();
}

// Step 5: Save & Update Job Persistence with Push Notifications


Future<void> saveJob() async {
if (!_formKey.currentState!.validate()) {
return;
}

setState(() {
isLoading = true;
});

try {
final jobData = {
'title': titleController.text.trim(),
'company': companyController.text.trim(),
'location': locationController.text.trim(),
'description': descriptionController.text.trim(),
'salary': salaryController.text.trim(),
'jobType': selectedJobType,
'category': selectedCategory,
};

if (widget.isEditMode) {
await FirebaseFirestore.instance
.collection('jobs')
.doc(widget.jobId)
.update({
...jobData,
'updatedAt': FieldValue.serverTimestamp(),
});

// NOTIFICATIONS: tell subscribers this job was edited.
unawaited(
NotificationService.instance.notifyJobUpdated(
jobId: widget.jobId!,
title: titleController.text.trim(),
company: companyController.text.trim(),
category: selectedCategory,
),
);
} else {
final newJob = await FirebaseFirestore.instance
.collection('jobs')
.add({
...jobData,
'publisherId': FirebaseAuth.instance.currentUser?.uid ?? '',
'createdAt': FieldValue.serverTimestamp(),
});

// NOTIFICATIONS: tell everyone subscribed to this category.
unawaited(
NotificationService.instance.notifyNewJobPosted(
jobId: newJob.id,
title: titleController.text.trim(),
company: companyController.text.trim(),
category: selectedCategory,
),
);
}

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
behavior: SnackBarBehavior.floating,
backgroundColor: const Color(0xFF10B981),
margin: const EdgeInsets.all(16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
content: Row(
children: [
const Icon(
Icons.check_circle_outline,
color: Colors.white,
),
const SizedBox(width: 12),
Expanded(
child: Text(
widget.isEditMode
? 'Job updated successfully!'
: 'Job added successfully!',
),
),
],
),
),
);

Navigator.pop(context);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
behavior: SnackBarBehavior.floating,
backgroundColor: Colors.red.shade700,
margin: const EdgeInsets.all(16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
content: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Icon(
Icons.error_outline,
color: Colors.white,
),
const SizedBox(width: 12),
Expanded(
child: Text(
widget.isEditMode
? 'Failed to update job:\n$e'
: 'Failed to add job:\n$e',
),
),
],
),
),
);
} finally {
if (mounted) {
setState(() {
isLoading = false;
});
}
}
}

