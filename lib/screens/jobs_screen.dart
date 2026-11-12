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
  Color get pageBg =>
      isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder =>
      isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface =>
      isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Inputs
  Color get inputBg => isDark ? const Color(0xFF0E1A14) : Colors.white;
  Color get inputBorder =>
      isDark ? const Color(0xFF1E382A) : const Color(0xFFE2EFE7);

  // Brand / Emerald Accent Colors
  Color get primary =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
  Color get primaryAccent =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  Color get primaryDark =>
      isDark ? const Color(0xFF059669) : const Color(0xFF047857);

  // Text Colors
  Color get textPrimary =>
      isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F241B);
  Color get textSecondary =>
      isDark ? const Color(0xFFA7C1B3) : const Color(0xFF4B6354);
  Color get textMuted =>
      isDark ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);

  // Icon Boxes & Badges
  Color get iconBoxBg =>
      isDark ? const Color(0x3310B981) : const Color(0x1F059669);
}

//Add Step 2: setup JobsScreen state variables, controllers, and lifecycle handlers
class JobsScreen extends StatefulWidget {
  final String? career;

  const JobsScreen({super.key, this.career});

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

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      final type = job.jobType.trim().toLowerCase();

      final matchesType =
          _selectedType == 'All' ||
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
      MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
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
                ...['Default', 'Title A-Z', 'Company A-Z'].map((option) {
                  final selected = _sortBy == option;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
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

  //Add Step 5: implement responsive scaffold layout and real-time jobs stream builder
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, isDark, _) {
        final colors = _JobsColors(isDark: isDark);

        return Scaffold(
          backgroundColor: colors.pageBg,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(colors),
                Expanded(
                  child: StreamBuilder<List<Job>>(
                    stream: _isCareerFiltered
                        ? _jobService.getRelatedJobs(widget.career!)
                        : _jobService.getJobs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return _buildLoading(colors);
                      }

                      if (snapshot.hasError) {
                        return _buildError(snapshot.error.toString(), colors);
                      }

                      final allJobs = snapshot.data ?? <Job>[];
                      final jobs = _filterJobs(allJobs);

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                        children: [
                          _buildHero(allJobs.length, colors),
                          const SizedBox(height: 22),
                          _buildSearchBar(colors),
                          const SizedBox(height: 18),
                          _buildFilterHeader(colors),
                          const SizedBox(height: 12),
                          _buildFilters(colors),
                          const SizedBox(height: 24),
                          _buildResultsHeader(jobs.length, colors),
                          const SizedBox(height: 14),

                          if (jobs.isEmpty)
                            _buildEmpty(allJobs.isEmpty, colors)
                          else
                            ...jobs.map(
                              (job) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildJobCard(job, colors),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
//Add Step 6: implement custom top navigation bar and emerald gradient hero banner


  Widget _buildTopBar(_JobsColors colors) {
    return Container(
      color: colors.pageBg,
      padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
      child: Row(
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: colors.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                      .withValues(alpha: colors.isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _isCareerFiltered ? 'Related Opportunities' : 'Available Jobs',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // Briefcase Icon Box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.cardBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: colors.cardBorder, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                      .withValues(alpha: colors.isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.work_outline_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHero(int count, _JobsColors colors) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.isDark
              ? const [
                  Color(0xFF03442C),
                  Color(0xFF065F46),
                  Color(0xFF047857),
                ]
              : const [
                  Color(0xFF047857),
                  Color(0xFF059669),
                  Color(0xFF10B981),
                ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: colors.isDark ? 0.35 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -48,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFDE68A),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'YOUR CAREER STARTS HERE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isCareerFiltered
                    ? 'Explore jobs for\n${widget.career}'
                    : 'Find your next\nbig opportunity.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  height: 1.17,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Discover opportunities and take the next step in your career journey.',
                style: TextStyle(
                  color: Color(0xFFE2FBEA),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count available ${count == 1 ? 'job' : 'jobs'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
//Add Step 7: implement interactive search bar and horizontal job type filter chips

  Widget _buildSearchBar(_JobsColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors.isDark ? Colors.black : const Color(0xFF059669))
                .withValues(alpha: colors.isDark ? 0.3 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Search jobs, companies, locations...',
          hintStyle: TextStyle(
            color: colors.textMuted,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.primary,
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }


  Widget _buildFilterHeader(_JobsColors colors) {
    return Row(
      children: [
        Icon(
          Icons.tune_rounded,
          color: colors.primary,
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(
          'Filter by job type',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(_JobsColors colors) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _jobTypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _jobTypes[index];
          final selected = _selectedType == type;

          return ChoiceChip(
            label: Text(type),
            selected: selected,
            showCheckmark: false,
            selectedColor: colors.primary,
            backgroundColor: colors.cardBg,
            side: BorderSide(
              color: selected ? colors.primary : colors.cardBorder,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            labelStyle: TextStyle(
              color: selected ? Colors.white : colors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
            onSelected: (_) {
              setState(() => _selectedType = type);
            },
          );
        },
      ),
    );
  }
}
