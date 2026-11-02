
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

  final TextEditingController _searchController =
  TextEditingController();

  String _selectedFilter = 'All';

  // PART 5: Track expanded application cards
  final Set<String> _expandedIds = {};

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

  // PART 2: Firestore applications
  Stream<QuerySnapshot<Map<String, dynamic>>>
  getUserApplications(String userId) {
    return _firestore
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  String getStringValue(
      Map<String, dynamic> data,
      String key,
      String fallback,
      ) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String getStatus(Map<String, dynamic> data) {
    return getStringValue(data, 'status', 'Applied');
  }

  DateTime? getAppliedDate(Map<String, dynamic> data) {
    final value = data['appliedAt'];
    return value is Timestamp ? value.toDate() : null;
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

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

  // PART 5: Status-specific colors
  Color statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'under review':
        return const Color(0xFFD97706);
      case 'shortlisted':
        return const Color(0xFF7C3AED);
      case 'interview':
        return const Color(0xFF4F46E5);
      case 'accepted':
        return const Color(0xFF059669);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return primary;
    }
  }

  // PART 5: Status-specific icons
  IconData statusIcon(String status) {
    switch (status.trim().toLowerCase()) {
      case 'under review':
        return Icons.visibility_outlined;
      case 'shortlisted':
        return Icons.star_outline_rounded;
      case 'interview':
        return Icons.groups_outlined;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
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

  // PART 6: Premium application card with AI Interview
  Widget buildApplicationCard(
      String id,
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
    final date = getAppliedDate(data);
    final expanded = _expandedIds.contains(id);
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFD1FAE5),
                            Color(0xFFA7F3D0),
                          ],
                        ),
                        borderRadius:
                        BorderRadius.circular(17),
                      ),
                      child: Center(
                        child: Text(
                          company[0].toUpperCase(),
                          style: const TextStyle(
                            color: primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            jobTitle,
                            style: const TextStyle(
                              color: dark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            company,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    buildStatusChip(status),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius:
                        BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: muted,
                            size: 14,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            formatDate(date),
                            style: const TextStyle(
                              color: muted,
                              fontSize: 11.5,
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
          Divider(height: 1, color: border),

          // PART 5: Expand/collapse button
          InkWell(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedIds.remove(id);
                } else {
                  _expandedIds.add(id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: color,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Application progress',
                      style: TextStyle(
                        color: dark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    expanded ? 'Hide' : 'View',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),

          // PART 5: Animated timeline
          AnimatedSize(
            duration:
            const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
              padding: const EdgeInsets.fromLTRB(
                19, 0, 19, 20,
              ),
              child: buildTimeline(status),
            )
                : const SizedBox(
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  // PART 5: Status chip
  Widget buildStatusChip(String status) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon(status),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // PART 5: Application progress timeline
  Widget buildTimeline(String status) {
    if (status.trim().toLowerCase() == 'rejected') {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Color(0xFFDC2626),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'This application was not selected.',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    const steps = [
      'Applied',
      'Under Review',
      'Shortlisted',
      'Interview',
      'Accepted',
    ];

    final current = steps.indexWhere(
          (step) =>
      step.toLowerCase() ==
          status.trim().toLowerCase(),
    );

    if (current < 0) {
      return Text(
        'Current status: $status',
        style: const TextStyle(
          color: muted,
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 9),

        ...List.generate(steps.length, (index) {
          final reached = index <= current;
          final isCurrent = index == current;
          final last = index == steps.length - 1;

          return Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 25,
                child: Column(
                  children: [
                    Icon(
                      reached
                          ? Icons.check_circle_rounded
                          : Icons
                          .radio_button_unchecked_rounded,
                      color: reached
                          ? primary
                          : const Color(0xFFCBD5E1),
                      size: 21,
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 29,
                        color: index < current
                            ? primary
                            : border,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          steps[index],
                          style: TextStyle(
                            color:
                            reached ? dark : muted,
                            fontSize: 12.5,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),

        const SizedBox(height: 4),

        const Text(
          'Progress is based on the current status provided by the administrator.',
          style: TextStyle(
            color: muted,
            fontSize: 10.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // PART 4: Empty search results
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

          // Sort newest first
          applications.sort((a, b) {
            final aDate = getAppliedDate(a.data());
            final bDate = getAppliedDate(b.data());

            if (aDate == null && bDate == null) {
              return 0;
            }
            if (aDate == null) return 1;
            if (bDate == null) return -1;

            return bDate.compareTo(aDate);
          });

          // PART 3: Summary counters
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

            return (title.contains(query) ||
                company.contains(query)) &&
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

                  buildSearch(),
                  const SizedBox(height: 14),

                  buildFilters(),
                  const SizedBox(height: 19),

                  if (filtered.isEmpty)
                    buildEmptyResults(total == 0)
                  else
                    ...filtered.map(
                          (doc) => buildApplicationCard(
                        doc.id,
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
