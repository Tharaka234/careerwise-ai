// Step 1: Imports and Dependencies

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_profile_screen.dart';


// Step 2: Dynamic Theme Color Palette (Premium Emerald Green Theme)

class _UserColors {
  final bool isDark;

  const _UserColors({required this.isDark});

  Color get pageBg => isDark ? const Color(0xFF0A140F) : const Color(0xFFF0FDF4);
  Color get cardBg => isDark ? const Color(0xFF13231B) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFD1FAE5);
  Color get cardSurface => isDark ? const Color(0xFF0F1E17) : const Color(0xFFF8FAF9);

  // Inputs
  Color get inputBg => isDark ? const Color(0xFF0E1A14) : const Color(0xFFF7FAF8);
  Color get inputBorder => isDark ? const Color(0xFF1E382A) : const Color(0xFFE2EFE7);

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


class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

// Step 4: State Management, Search Controller & Role Filters
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'All'; // 'All', 'Candidates', 'Admins'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Step 5: Screen Scaffold, StreamBuilder & Real-time Metrics

@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<bool>(
    valueListenable: AdminThemeManager.isDarkMode,
    builder: (context, isDark, _) {
      final colors = _UserColors(isDark: isDark);

      return Scaffold(
        backgroundColor: colors.pageBg,
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            final allDocs = snapshot.data?.docs ?? [];
            final filteredDocs = _filterUsers(allDocs);

            int totalUsers = allDocs.length;
            int adminCount = 0;
            int candidateCount = 0;

            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final role = data['role']?.toString().toLowerCase() ?? '';
              if (role == 'admin') {
                adminCount++;
              } else {
                candidateCount++;
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(
                    colors: colors,
                    totalCount: totalUsers,
                    adminCount: adminCount,
                    candidateCount: candidateCount,
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
                            // Search & Role Filter Bar
                            _buildSearchAndFilters(colors),

                            const SizedBox(height: 20),

                            // Content list
                            if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                                !snapshot.hasData)
                              _loadingCard(colors)
                            else if (snapshot.hasError)
                              _errorCard(
                                'Error loading users: ${snapshot.error}',
                                colors,
                              )
                            else if (filteredDocs.isEmpty)
                                _emptyCard(
                                  title: _searchQuery.isEmpty
                                      ? 'No users found'
                                      : 'No matching users',
                                  subtitle: _searchQuery.isEmpty
                                      ? 'Registered platform candidates and admins will appear here.'
                                      : 'Try searching with a different name or email.',
                                  colors: colors,
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredDocs.length,
                                  separatorBuilder: (context, index) =>
                                  const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final doc = filteredDocs[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>? ??
                                            {};
                                    return _userCard(
                                      uid: doc.id,
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

// Step 6: Multi-Attribute Real-Time Filter Logic
List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> docs) {
  return docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final firstName = data['firstName']?.toString().toLowerCase() ?? '';
    final lastName = data['lastName']?.toString().toLowerCase() ?? '';
    final email = data['email']?.toString().toLowerCase() ?? '';
    final phone = data['phone']?.toString().toLowerCase() ?? '';
    final role = data['role']?.toString().toLowerCase() ?? '';

    final matchesQuery = _searchQuery.isEmpty ||
        firstName.contains(_searchQuery) ||
        lastName.contains(_searchQuery) ||
        email.contains(_searchQuery) ||
        phone.contains(_searchQuery);

    if (!matchesQuery) return false;

    if (_selectedRoleFilter == 'Admins') {
      return role == 'admin';
    } else if (_selectedRoleFilter == 'Candidates') {
      return role != 'admin';
    }

    return true;
  }).toList();
}