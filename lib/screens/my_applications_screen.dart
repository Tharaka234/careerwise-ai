
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
  static const Color background = Color(0xFFF0FDF4);
  static const Color dark = Color(0xFF0F241B);
  static const Color muted = Color(0xFF4B6354);

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get applications belonging to the logged-in user
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserApplications(
      String userId,
      ) {
    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Format Firestore application date
  String formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Date unavailable';
    }

    final date = value.toDate();

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Build an individual application item
  Widget buildApplicationItem(Map<String, dynamic> data) {
    final jobTitle = data['jobTitle']?.toString() ?? 'Unknown Job';
    final company = data['company']?.toString() ?? 'Unknown Company';
    final status = data['status']?.toString() ?? 'Applied';
    final appliedDate = formatDate(data['appliedAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD1FAE5),
        ),
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
                size: 15,
                color: muted,
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

  // Message shown when no data is available
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
            Icon(
              icon,
              color: primary,
              size: 60,
            ),

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
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: dark,
          ),
          onPressed: () {
            Navigator.maybePop(context);
          },
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
        'Please log in to view your applications.',
      )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

          // Firestore documents
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

          // Empty state
          if (applications.isEmpty) {
            return buildMessageState(
              Icons.work_outline_rounded,
              'No applications yet',
              'Your submitted job applications will appear here.',
            );
          }

          // Applications list
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 800,
              ),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Your Career Journey',
                    style: TextStyle(
                      color: dark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${applications.length} submitted applications',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 24),

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
