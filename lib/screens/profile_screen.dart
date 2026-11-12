import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF0FDF4),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),

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

              const Text(
                'CareerWise User',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'user@example.com',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Candidate Member',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}