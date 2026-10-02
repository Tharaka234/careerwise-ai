import 'package:flutter/material.dart';
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
      body: const Center(
        child: Text('Loading applications...'),
      ),
    );
  }
}