import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Applications'),
        ),
        body: const Center(
          child: Text(
            'Please login to view your applications.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final applications = snapshot.data?.docs ?? [];

          if (applications.isEmpty) {
            return _emptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final data = applications[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['jobTitle']?.toString() ?? 'Unknown Job'),
                subtitle: Text(data['company']?.toString() ?? 'Unknown Company'),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Applications Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'When you apply for a job, your application will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Browse Jobs'),
            ),
          ],
        ),
      ),
    );
  }
}