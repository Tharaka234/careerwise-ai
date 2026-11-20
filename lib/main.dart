import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';

// ==========================================
// PART 1 - FIREBASE INITIALIZATION
// ==========================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('====================================');
  debugPrint('CAREERWISE FIREBASE INITIALIZED');
  debugPrint(
    'PROJECT ID: ${Firebase.app().options.projectId}',
  );
  debugPrint('====================================');

  runApp(const CareerWiseApp());
}

// ==========================================
// CAREERWISE APPLICATION
// ==========================================

class CareerWiseApp extends StatelessWidget {
  const CareerWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareerWise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ==========================================
// BASIC AUTHENTICATION GATE
// ==========================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> checkAdmin(String uid) async {
    // Temporary basic implementation.
    // Full Firestore admin verification comes in Part 5.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: checkAdmin(snapshot.data!.uid),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState !=
                  ConnectionState.done) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (adminSnapshot.data == true) {
                return const AdminDashboardScreen();
              }

              return const HomeScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
