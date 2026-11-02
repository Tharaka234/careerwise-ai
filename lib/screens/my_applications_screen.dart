
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState
    extends State<MyApplicationsScreen> {
  static const Color primary = Color(0xFF059669);
  static const Color deepGreen = Color(0xFF065F46);
  static const Color lightGreen = Color(0xFF10B981);
  static const Color background = Color(0xFFF0FDF4);
  static const Color dark = Color(0xFF0F241B);
  static const Color muted = Color(0xFF4B6354);
  static const Color border = Color(0xFFD1FAE5);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PART 2: Firebase real-time applications
  Stream<QuerySnapshot<Map<String, dynamic>>>
  getUserApplications(String userId) {
    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  String formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Date unavailable';
    }

    final date = value.toDate();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // PART 3: Application status calculations
  bool isInProgress(String status) {
    final normalized = status.trim().toLowerCase();

    return normalized != 'accepted' &&
        normalized != 'rejected';
  }

  String getStatus(Map<String, dynamic> data) {
    final value = data['status']?.toString().trim() ?? '';
    return value.isEmpty ? 'Applied' : value;
  }

  // PART 3: Premium hero section
  Widget buildHero(int total) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepGreen,
            primary,
            lightGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -55,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 35,
              bottom: -75,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.work_history_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Your career journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  const Text(
                    'Stay organized and track every opportunity in one place.',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.18,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$total Applications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PART 3: Reusable summary card
  Widget buildSummaryCard(
      String title,
      int count,
      IconData icon,
      Color color,
      Color iconBackground,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: const TextStyle(
              color: dark,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // PART 3: Summary statistics layout
  Widget buildSummarySection({
    required int total,
    required int inProgress,
    required int accepted,
  }) {
    return Row(
      children: [
        Expanded(
          child: buildSummaryCard(
            'Total',
            total,
            Icons.description_outlined,
            primary,
            const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildSummaryCard(
            'In Progress',
            inProgress,
            Icons.timelapse_rounded,
            const Color(0xFFD97706),
            const Color(0xFFFFFBEB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: buildSummaryCard(
            'Accepted',
            accepted,
            Icons.check_circle_outline_rounded,
            const Color(0xFF059669),
            const Color(0xFFECFDF5),
          ),
        ),
      ],
    );
  }

  // PART 2: Individual application card
  Widget buildApplicationItem(Map<String, dynamic> data) {
    final jobTitle =
        data['jobTitle']?.toString() ?? 'Unknown Job';
    final company =
        data['company']?.toString() ?? 'Unknown Company';
    final status = getStatus(data);
    final appliedDate = formatDate(data['appliedAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            jobTitle,
            style: const TextStyle(
              color: dark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            company,
            style: const TextStyle(
              color: muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: primary,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                color: muted,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                appliedDate,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PART 2: Loading-independent message state
  Widget buildMessageState(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary, size: 60),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: dark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: dark,
            size: 19,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Applications',
          style: TextStyle(
            color: dark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: user == null
          ? buildMessageState(
        Icons.lock_outline_rounded,
        'Sign in required',
        'Please log in to view your job applications.',
      )
          : StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: getUserApplications(user.uid),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState ==
              ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return buildMessageState(
              Icons.cloud_off_outlined,
              'Unable to load applications',
              'Please check your connection and try again.',
            );
          }

          final applications = [
            ...?snapshot.data?.docs,
          ];

          // Sort newest applications first
          applications.sort((a, b) {
            final aDate = a.data()['appliedAt'];
            final bDate = b.data()['appliedAt'];

            if (aDate is Timestamp &&
                bDate is Timestamp) {
              return bDate.compareTo(aDate);
            }

            if (aDate is Timestamp) return -1;
            if (bDate is Timestamp) return 1;
            return 0;
          });

          // PART 3: Dynamic summary calculations
          final total = applications.length;

          final inProgress = applications.where((doc) {
            final status = getStatus(doc.data());
            return isInProgress(status);
          }).length;

          final accepted = applications.where((doc) {
            final status = getStatus(doc.data());
            return status.trim().toLowerCase() ==
                'accepted';
          }).length;

          // PART 3: Premium layout
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 800,
              ),
              child: ListView(
                physics:
                const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  30,
                ),
                children: [
                  // Premium hero
                  buildHero(total),

                  const SizedBox(height: 17),

                  // Dynamic summary cards
                  buildSummarySection(
                    total: total,
                    inProgress: inProgress,
                    accepted: accepted,
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Your applications',
                    style: TextStyle(
                      color: dark,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$total submitted applications',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 17),

                  if (applications.isEmpty)
                    buildMessageState(
                      Icons.work_outline_rounded,
                      'No applications yet',
                      'Your submitted applications will appear here once you apply.',
                    )
                  else
                    ...applications.map(
                          (doc) => buildApplicationItem(
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
}
