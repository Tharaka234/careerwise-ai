import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF059669),
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Logout confirmation dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to log out of CareerWise?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.popUntil(
                  context,
                      (route) => route.isFirst,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email available';

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF0FDF4),
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: user != null
            ? FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            : null,
        builder: (context, snapshot) {
          final userData = snapshot.data?.data();

          final firstName = userData?['firstName'] as String? ?? '';
          final lastName = userData?['lastName'] as String? ?? '';

          final fullName = '$firstName $lastName'.trim();

          final displayName = fullName.isNotEmpty
              ? fullName
              : (user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : 'CareerWise User');

          final phone = userData?['phone'] as String? ?? '';
          final role = userData?['role'] as String? ?? 'Candidate';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Avatar
                  Container(
                    width: 116,
                    height: 116,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF34D399),
                          Color(0xFF059669),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 65,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // User Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // User Email
                  Text(email),

                  const SizedBox(height: 12),

                  // User Role
                  Text(
                    '$role Member',
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Account Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 18),

                        _buildInfoRow(
                          Icons.email_outlined,
                          'Email Address',
                          email,
                        ),

                        const Divider(),

                        if (phone.isNotEmpty) ...[
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Phone Number',
                            phone,
                          ),
                          const Divider(),
                        ],

                        _buildInfoRow(
                          Icons.verified_user_outlined,
                          'Account Status',
                          'Active',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
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