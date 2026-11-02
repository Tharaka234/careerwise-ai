
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
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

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Container(
                  width: 85,
                  height: 85,

                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(25),
                  ),

                  child: const Icon(
                    Icons.work_history_rounded,
                    size: 42,
                    color: primary,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Your Career Journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Track all your job applications in one place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),

                  child: const Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: primary,
                        size: 45,
                      ),

                      SizedBox(height: 16),

                      Text(
                        'My Job Applications',
                        style: TextStyle(
                          color: dark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      Text(
                        'Your submitted applications will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
