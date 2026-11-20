import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/notification_service.dart';
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
// PART 3 - FIRESTORE DIAGNOSTIC TEST
// ==========================================

Future<void> testCareerWiseData(String uid) async {
  debugPrint('');
  debugPrint('========== CAREERWISE FIRESTORE TEST ==========');

  debugPrint(
    'PROJECT ID: ${Firebase.app().options.projectId}',
  );

  // ==========================================
  // TEST 1 - JOBS COLLECTION
  // ==========================================

  try {
    final jobs = await FirebaseFirestore.instance
        .collection('jobs')
        .limit(5)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint('JOBS FOUND: ${jobs.docs.length}');

    for (final doc in jobs.docs) {
      debugPrint('JOB DOCUMENT: ${doc.id}');
    }
  } on FirebaseException catch (e) {
    debugPrint('JOBS FIREBASE ERROR: ${e.code}');
    debugPrint('JOBS ERROR MESSAGE: ${e.message}');
  } on TimeoutException catch (e) {
    debugPrint('JOBS TIMEOUT: $e');
  } catch (e) {
    debugPrint('JOBS ERROR: $e');
  }

  // ==========================================
  // TEST 2 - APPLICATIONS COLLECTION
  // ==========================================

  try {
    final applications = await FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: uid)
        .limit(5)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint(
      'APPLICATIONS FOUND: ${applications.docs.length}',
    );

    for (final doc in applications.docs) {
      debugPrint('APPLICATION DOCUMENT: ${doc.id}');
    }
  } on FirebaseException catch (e) {
    debugPrint('APPLICATIONS FIREBASE ERROR: ${e.code}');
    debugPrint('APPLICATIONS ERROR MESSAGE: ${e.message}');
  } on TimeoutException catch (e) {
    debugPrint('APPLICATIONS TIMEOUT: $e');
  } catch (e) {
    debugPrint('APPLICATIONS ERROR: $e');
  }

  // ==========================================
  // TEST 3 - PRIVATE NOTIFICATIONS
  // ==========================================

  try {
    final notifications = await FirebaseFirestore.instance
        .collection('notification_history')
        .where('audience', isEqualTo: 'user')
        .where('recipientUid', isEqualTo: uid)
        .limit(5)
        .get(
      const GetOptions(source: Source.server),
    )
        .timeout(const Duration(seconds: 15));

    debugPrint(
      'PRIVATE NOTIFICATIONS FOUND: '
          '${notifications.docs.length}',
    );

    for (final doc in notifications.docs) {
      debugPrint('NOTIFICATION DOCUMENT: ${doc.id}');
    }
  } on FirebaseException catch (e) {
    debugPrint('NOTIFICATIONS FIREBASE ERROR: ${e.code}');
    debugPrint('NOTIFICATIONS ERROR MESSAGE: ${e.message}');
  } on TimeoutException catch (e) {
    debugPrint('NOTIFICATIONS TIMEOUT: $e');
  } catch (e) {
    debugPrint('NOTIFICATIONS ERROR: $e');
  }

  debugPrint('========== TEST COMPLETED ==========');
  debugPrint('');
}



// ==========================================
// CAREERWISE APPLICATION
// ==========================================


// ==========================================
// PART 4 - CAREERWISE APPLICATION SETUP
// ==========================================

class CareerWiseApp extends StatelessWidget {
  const CareerWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareerWise',

      // Notification tap navigation.
      navigatorKey: appNavigatorKey,

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


  // ==========================================
  // PART 5 - FIREBASE ADMIN ROLE VERIFICATION
  // ==========================================

  Future<bool> checkAdmin(String uid) async {
    debugPrint('========== ADMIN CHECK ==========');

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get(
        const GetOptions(source: Source.server),
      )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'Admin document exists: ${adminDoc.exists}',
      );

      if (!adminDoc.exists) {
        debugPrint('Normal user: no admin document');
        return false;
      }

      final role = adminDoc.data()?['role'];

      debugPrint('Admin role: $role');

      return role
          ?.toString()
          .trim()
          .toLowerCase() ==
          'admin';
    } on FirebaseException catch (e) {
      debugPrint('ADMIN FIREBASE ERROR: ${e.code}');
      debugPrint('ADMIN ERROR MESSAGE: ${e.message}');
      rethrow;
    } on TimeoutException catch (e) {
      debugPrint('ADMIN CHECK TIMEOUT: $e');
      rethrow;
    } catch (e) {
      debugPrint('ADMIN CHECK ERROR: $e');
      rethrow;
    }
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
          final user = snapshot.data!;

          return FutureBuilder<bool>(
            future: checkAdmin(user.uid),
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
