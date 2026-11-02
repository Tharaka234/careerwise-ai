
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
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // PART 4: Search and filter state
  final TextEditingController _searchController =
  TextEditingController();

  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'In Progress',
    'Accepted',
    'Rejected',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool isInProgress(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized != 'accepted' &&
        normalized != 'rejected';
  }

  String getStatus(Map<String, dynamic> data) {
    final value = data['status']?.toString().trim() ?? '';
    return value.isEmpty ? 'Applied' : value;
  }

  String getStringValue(
      Map<String, dynamic> data,
      String key,
      String fallback,
      ) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  // PART 4: Check selected status filter
  bool matchesFilter(String status) {
    final normalized = status.trim().toLowerCase();

    switch (_selectedFilter) {
      case 'In Progress':
        return isInProgress(status);
      case 'Accepted':
        return normalized == 'accepted';
      case 'Rejected':
        return normalized == 'rejected';
      default:
        return true;
    }
  }

  // PART 3: Premium hero
  Widget buildHero(int total) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deepGreen, primary, lightGreen],
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
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
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
                  color: Colors.white.withValues(
                    alpha: 0.07,
                  ),
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
                      borderRadius:
                      BorderRadius.circular(15),
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
                      borderRadius:
                      BorderRadius.circular(12),
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

  // PART 3: Summary card
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
            primary,
            const Color(0xFFECFDF5),
          ),
        ),
      ],
    );
  }

  // PART 4: Search bar
  Widget buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          color: dark,
          fontSize: 13.5,
        ),
        decoration: InputDecoration(
          hintText: 'Search jobs or companies...',
          hintStyle: const TextStyle(
            color: muted,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: primary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(
              Icons.close_rounded,
              color: muted,
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // PART 4: Filter chips
  Widget buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) =>
        const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: primary,
            side: BorderSide(
              color: selected ? primary : border,
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }

  // PART 2: Application item
  Widget buildApplicationItem(
      Map<String, dynamic> data,
      ) {
    final jobTitle = getStringValue(
      data,
      'jobTitle',
      'Unknown Job',
    );

    final company = getStringValue(
      data,
      'company',
      'Unknown Company',
    );

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

  // PART 4: No matching applications
  Widget buildEmptyResults(bool noApplications) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(
            noApplications
                ? Icons.work_outline_rounded
                : Icons.search_off_rounded,
            color: primary,
            size: 55,
          ),
          const SizedBox(height: 18),
          Text(
            noApplications
                ? 'No applications yet'
                : 'No matching applications',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: dark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            noApplications
                ? 'Your job applications will appear here once you apply.'
                : 'Try a different search or filter to find your applications.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          if (!noApplications) ...[
            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedFilter = 'All';
                });
              },
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

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
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: dark,
            size: 19,
          ),
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
          if (snapshot.connectionState ==
              ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primary,
              ),
            );
          }

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

          // Newest applications first
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

          // PART 3: Summary calculations
          final total = applications.length;

          final inProgress =
              applications.where((doc) {
                return isInProgress(
                  getStatus(doc.data()),
                );
              }).length;

          final accepted =
              applications.where((doc) {
                return getStatus(doc.data())
                    .toLowerCase() ==
                    'accepted';
              }).length;

          // PART 4: Search and filter
          final query = _searchController.text
              .trim()
              .toLowerCase();

          final filtered =
          applications.where((doc) {
            final data = doc.data();

            final title = getStringValue(
              data,
              'jobTitle',
              'Unknown Job',
            ).toLowerCase();

            final company = getStringValue(
              data,
              'company',
              'Unknown Company',
            ).toLowerCase();

            final status = getStatus(data);

            final matchesSearch =
                title.contains(query) ||
                    company.contains(query);

            return matchesSearch &&
                matchesFilter(status);
          }).toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 800,
              ),
              child: ListView(
                physics:
                const BouncingScrollPhysics(),
                padding:
                const EdgeInsets.fromLTRB(
                  18, 8, 18, 30,
                ),
                children: [
                  buildHero(total),
                  const SizedBox(height: 17),

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

                  // PART 4: Search bar
                  buildSearch(),

                  const SizedBox(height: 14),

                  // PART 4: Filter chips
                  buildFilters(),

                  const SizedBox(height: 19),

                  if (filtered.isEmpty)
                    buildEmptyResults(total == 0)
                  else
                    ...filtered.map(
                          (doc) =>
                          buildApplicationItem(
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
