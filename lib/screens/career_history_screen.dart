//Step 1: implement CareerHistoryColors design system with dark and light themes
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_profile_screen.dart';

// EMERALD GREEN THEME DESIGN SYSTEM & STYLES

class CareerHistoryColors {
  final bool isDark;
  final Color pageBg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color tagBg;
  final Color tagBorder;
  final Color searchFill;
  final Color iconBg;

  CareerHistoryColors({required this.isDark})
      : pageBg = isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4),
        cardBg = isDark ? const Color(0xFF132A1F) : Colors.white,
        cardBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFD1FAE5),
        textPrimary = isDark ? Colors.white : const Color(0xFF0F172A),
        textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        primary = const Color(0xFF059669),
        primaryDark = const Color(0xFF044E36),
        accent = const Color(0xFF10B981),
        tagBg = isDark ? const Color(0xFF0E2319) : const Color(0xFFECFDF5),
        tagBorder = isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.35)
            : const Color(0xFFA7F3D0),
        searchFill = isDark ? const Color(0xFF0A1F16) : Colors.white,
        iconBg = isDark ? const Color(0xFF0E2319) : const Color(0xFFECFDF5);
}
// Step 2: implement CareerStyle utility class with card, gradient, button, and JSON helpers
class CareerStyle {
  // Emerald Brand Colors
  static const primary = Color(0xFF059669);
  static const primaryDark = Color(0xFF044E36);
  static const accent = Color(0xFF10B981);
  static const mintLight = Color(0xFFECFDF5);
  static const mintBorder = Color(0xFFA7F3D0);

  // Backward compatibility aliases
  static const blue = Color(0xFF059669);
  static const navy = Color(0xFF044E36);
  static const indigo = Color(0xFF10B981);
  static const background = Color(0xFFF0FDF4);
  static const dark = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFD1FAE5);

  static BoxDecoration card({
    double radius = 20,
    required CareerHistoryColors colors,
  }) {
    return BoxDecoration(
      color: colors.cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: colors.cardBorder),
      boxShadow: [
        BoxShadow(
          color: colors.isDark
              ? Colors.black.withValues(alpha: 0.30)
              : colors.primaryDark.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration gradient({double radius = 25}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryDark, primary, accent],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }

  static Widget heading(
    String title, {
    String? subtitle,
    required CareerHistoryColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  static Widget iconBox(
    IconData icon, {
    required CareerHistoryColors colors,
    Color? color,
    Color? backgroundColor,
    double size = 46,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.iconBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.tagBorder),
      ),
      child: Icon(
        icon,
        color: color ?? colors.primary,
        size: size * 0.49,
      ),
    );
  }

  static Widget button({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 51,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryDark, primary, accent],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: Colors.white, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  static String date(Timestamp? timestamp) {
    if (timestamp == null) return 'Date unavailable';

    final date = timestamp.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} '
        '${date.year} • $hour:$minute $period';
  }

  static String field(
    Map<String, dynamic> data,
    String key, [
    String fallback = 'Not provided',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  static Map<String, dynamic>? parse(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  static List<dynamic> list(dynamic value) {
    return value is List ? value : [];
  }

  static List<Map<String, dynamic>> careers(String value) {
    final decoded = parse(value);
    return list(decoded?['careers'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

// Step 3: setup CareerHistoryScreen with Firestore real-time stream and lifecycle handlers

class CareerHistoryScreen extends StatefulWidget {
  const CareerHistoryScreen({super.key});

  @override
  State<CareerHistoryScreen> createState() => _CareerHistoryScreenState();
}

class _CareerHistoryScreenState extends State<CareerHistoryScreen> {
  final TextEditingController _search = TextEditingController();

  String _sort = 'Newest first';
  bool _deleting = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _historyStream;
  String? _streamUserId;

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final user = FirebaseAuth.instance.currentUser;
    _streamUserId = user?.uid;

    if (user != null) {
      _historyStream = FirebaseFirestore.instance
          .collection('career_recommendations')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    } else {
      _historyStream = null;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }


  // Step 4: implement assessment deletion dialog with Firestore sync and snackbar notifications
  Future<void> _deleteRecommendation(String id,
      CareerHistoryColors colors,) async {
    if (_deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            backgroundColor: colors.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(23),
              side: BorderSide(color: colors.cardBorder),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delete assessment?',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'This saved career recommendation will be permanently deleted.',
              style: TextStyle(
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('career_recommendations')
          .doc(id)
          .delete();

      if (!mounted) return;

      _snack('Assessment deleted successfully.');
    } catch (e) {
      debugPrint('Delete recommendation error: $e');
      if (!mounted) return;
      _snack('Unable to delete assessment.', error: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? const Color(0xFFDC2626)
              : const Color(0xFF059669),
          content: Text(message),
        ),
      );
  }

  // Step 5: implement responsive scaffold and AdminThemeManager reactive stream builder
  Widget _buildBackButton(
    BuildContext context,
    CareerHistoryColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: colors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black26
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.uid != _streamUserId) {
      _setupStream();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = CareerHistoryColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          appBar: AppBar(
            backgroundColor: colors.pageBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: _buildBackButton(context, colors),
            title: Text(
              'Career History',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: user == null
              ? _empty(
                  Icons.lock_outline_rounded,
                  'Sign in required',
                  'Please log in to view your career history.',
                  colors,
                )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _historyStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && !snapshot.hasError) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colors.primary,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _empty(
                        Icons.cloud_off_outlined,
                        'Unable to load history',
                        'Please check your connection and try again.',
                        colors,
                      );
                    }

                    final docs = [...?snapshot.data?.docs];

                    docs.sort((a, b) {
                      final aTime = a.data()['createdAt'];
                      final bTime = b.data()['createdAt'];

                      final aDate = aTime is Timestamp
                          ? aTime.toDate()
                          : DateTime(1970);
                      final bDate = bTime is Timestamp
                          ? bTime.toDate()
                          : DateTime(1970);

                      return _sort == 'Newest first'
                          ? bDate.compareTo(aDate)
                          : aDate.compareTo(bDate);
                    });

                    final query = _search.text.trim().toLowerCase();

                    final filtered = docs.where((doc) {
                      final data = doc.data();

                      final careers = CareerStyle.careers(
                        CareerStyle.field(data, 'recommendation', ''),
                      );

                      final careerNames = careers
                          .map((c) => c['title']?.toString() ?? '')
                          .join(' ');

                      final searchText = [
                        CareerStyle.field(data, 'careerGoal'),
                        CareerStyle.field(data, 'education'),
                        CareerStyle.field(data, 'skills'),
                        CareerStyle.field(data, 'interests'),
                        careerNames,
                      ].join(' ').toLowerCase();

                      return searchText.contains(query);
                    }).toList();

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _hero(docs.length),
                            const SizedBox(height: 25),
                            CareerStyle.heading(
                              'Saved Assessments',
                              subtitle:
                                  'Revisit your AI-powered career insights',
                              colors: colors,
                            ),
                            const SizedBox(height: 16),
                            _searchAndSort(colors),
                            const SizedBox(height: 17),
                            if (filtered.isEmpty)
                              _emptyCard(docs.isEmpty, colors)
                            else
                              ...filtered.map(
                                (doc) => _historyCard(
                                  doc.id,
                                  doc.data(),
                                  colors,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

