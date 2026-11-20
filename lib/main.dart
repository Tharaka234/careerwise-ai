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

  // Run Wi-Fi / Firestore test without
  // blocking the application startup.
  unawaited(testWifiFirestoreConnection());

  runApp(const CareerWiseApp());
}


// ==========================================
// PART 2 - WIFI / FIRESTORE CONNECTION TEST
// ==========================================

Future<void> testWifiFirestoreConnection() async {
  debugPrint('');
  debugPrint('========== WIFI FIRESTORE TEST START ==========');

  debugPrint(
    'PROJECT ID: ${Firebase.app().options.projectId}',
  );

  debugPrint(
    'AUTH USER: ${FirebaseAuth.instance.currentUser != null}',
  );

  try {
    final result = await FirebaseFirestore.instance
        .collection('jobs')
        .limit(1)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint('WIFI FIRESTORE SUCCESS');
    debugPrint('JOBS DOCUMENT COUNT: ${result.docs.length}');
    debugPrint('DATA FROM CACHE: ${result.metadata.isFromCache}');
  } on TimeoutException catch (e) {
    debugPrint('WIFI FIRESTORE FAILED');
    debugPrint('ERROR TYPE: TIMEOUT');
    debugPrint('ERROR: $e');
  } on FirebaseException catch (e) {
    debugPrint('WIFI FIRESTORE FAILED');
    debugPrint('ERROR CODE: ${e.code}');
    debugPrint('ERROR MESSAGE: ${e.message}');

    if (e.code == 'unavailable') {
      debugPrint(
        'POSSIBLE NETWORK ISSUE: Firestore server unavailable',
      );
    } else if (e.code == 'permission-denied') {
      debugPrint(
        'POSSIBLE RULES ISSUE: Check Firestore permissions',
      );
    } else if (e.code == 'failed-precondition') {
      debugPrint(
        'POSSIBLE INDEX ISSUE: Check Firestore indexes',
      );
    }
  } catch (e) {
    debugPrint('WIFI FIRESTORE FAILED');
    debugPrint('ERROR: $e');
  }

  debugPrint('========== WIFI FIRESTORE TEST END ==========');
  debugPrint('');
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
