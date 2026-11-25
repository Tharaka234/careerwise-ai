import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'package:careerwise-ai/firebase_options.dart';

import 'notification_types.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

import 'package:careerwise-ai/model/job.dart';
import 'package:careerwise-ai/screens/job_details_screen.dart';
import 'package:careerwise-ai/screens/my_applications_screen.dart';
import 'package:careerwise-ai/screens/profile_screen.dart';
// =======================================================================
// GLOBALS
// =======================================================================

/// Used by MaterialApp so notifications can open screens without a
/// BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey =
GlobalKey<NavigatorState>();

/// FCM background / terminated handler.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (message.notification == null &&
      message.data['title'] != null) {
    await NotificationService.showDataOnlyMessageInBackground(
      message,
    );
  }
}

/// What the user chose in the Notification Settings screen.
class NotificationPrefs {
  const NotificationPrefs({
    required this.announcements,
    required this.categories,
    required this.isAdmin,
  });

  final bool announcements;
  final Set<String> categories;
  final bool isAdmin;
}

/// Firestore field names for the notification_history collection.
class HistoryFields {
  HistoryFields._();

  static const String collection = 'notification_history';
  static const String title = 'title';
  static const String body = 'body';
  static const String type = 'type';
  static const String audience = 'audience';
  static const String category = 'category';
  static const String jobId = 'jobId';
  static const String senderUid = 'senderUid';
  static const String recipientUid = 'recipientUid';
  static const String applicationId = 'applicationId';
  static const String createdAt = 'createdAt';

  /// Field on notification_settings/{uid} listing deleted items.
  static const String dismissed = 'dismissedHistory';
}

/// Who a history item was meant for.
class HistoryAudience {
  HistoryAudience._();

  static const String everyone = 'everyone';
  static const String admins = 'admins';
  static const String category = 'category';
  static const String user = 'user';
}

class NotificationHistoryItem {
  const NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    required this.createdAt,
    this.category,
    this.jobId,
    this.recipientUid,
    this.applicationId,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String audience;
  final String? category;
  final String? jobId;
  final String? recipientUid;
  final String? applicationId;
  final DateTime? createdAt;

  factory NotificationHistoryItem.fromMap(
      String id,
      Map<String, dynamic> m,
      ) {
    final ts = m[HistoryFields.createdAt];
    final category = m[HistoryFields.category]?.toString();

    return NotificationHistoryItem(
      id: id,
      title: m[HistoryFields.title]?.toString() ?? '',
      body: m[HistoryFields.body]?.toString() ?? '',
      type: m[HistoryFields.type]?.toString() ??
          NotificationTypes.announcement,
      audience: m[HistoryFields.audience]?.toString() ??
          HistoryAudience.everyone,
      category:
      (category == null || category.isEmpty) ? null : category,
      jobId: m[HistoryFields.jobId]?.toString(),
      recipientUid: m[HistoryFields.recipientUid]?.toString(),
      applicationId: m[HistoryFields.applicationId]?.toString(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

// =======================================================================
// SERVICE
// =======================================================================

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  // ---------------------------------------------------------------------
  // Config
  // ---------------------------------------------------------------------

  /// Required fields for profile completeness.
  static const List<String> _requiredProfileFields = [
    'firstName',
    'lastName',
    'phone',
  ];

  static const Duration _profileReminderDelay =
  Duration(hours: 24);

  static const int _profileReminderId = 4101;

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    NotificationChannels.highImportance,
    NotificationChannels.highImportanceName,
    description:
    NotificationChannels.highImportanceDescription,
    importance: Importance.high,
  );

  static const NotificationDetails _details =
  NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationChannels.highImportance,
      NotificationChannels.highImportanceName,
      channelDescription:
      NotificationChannels.highImportanceDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const InitializationSettings _initSettings =
  InitializationSettings(
    android: AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    ),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );

  // ---------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------

  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool _initialized = false;
  String? _currentUid;
  bool _isAdmin = false;
  String? _adminCheckedUid;
  DateTime? _lastInterviewSync;

  /// Notifications are supported on Android and iOS.
  static bool get isSupported =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  bool get isAdmin => _isAdmin;

  /// Resolves the admin role from Firestore.
  /// Works on mobile, web and desktop.
  Future<bool> refreshAdminStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      _isAdmin = false;
      _adminCheckedUid = null;
      return false;
    }

    if (_adminCheckedUid == uid) return _isAdmin;

    _isAdmin = await _checkIsAdmin(uid);
    _adminCheckedUid = uid;

    return _isAdmin;
  }

  // =====================================================================
  // INIT
  // =====================================================================

  Future<void> init() async {
    if (_initialized || !isSupported) return;

    tzdata.initializeTimeZones();

    // Initialize local notifications.
    await _local.initialize(
      settings: _initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayloadString(response.payload);
      },
    );

    // Create Android notification channel.
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request notification permissions.
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configure iOS foreground notifications.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground notification listener.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // STATE 2: BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_navigateWhenReady(message.data));
    });

// STATE 3: TERMINATED
    final initialMessage = await messaging.getInitialMessage();

    if (initialMessage != null) {
      unawaited(_navigateWhenReady(initialMessage.data));
    }

// Handle application launch from a local notification.
    final launchDetails =
    await _local.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handlePayloadString(
        launchDetails!.notificationResponse?.payload,
      );
    }


    // Token and topic subscriptions follow the logged-in user.
    messaging.onTokenRefresh.listen(_onTokenRefresh);

    FirebaseAuth.instance.authStateChanges().listen(
      _onAuthChanged,
    );

    _initialized = true;
  }
  // =====================================================================
// AUTH / TOKEN / TOPICS
// =====================================================================

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _currentUid = null;
      _isAdmin = false;
      _adminCheckedUid = null;
      return;
    }

    if (_currentUid == user.uid) return;

    _currentUid = user.uid;

    try {
      await _onLogin(user);
    } catch (e) {
      debugPrint('Notification login setup error: $e');
    }
  }

  Future<void> _onLogin(User user) async {
    final uid = user.uid;
    final messaging = FirebaseMessaging.instance;

    _isAdmin = await _checkIsAdmin(uid);
    _adminCheckedUid = uid;

    final settingsRef = _db
        .collection('notification_settings')
        .doc(uid);

    final snapshot = await settingsRef.get();

    final saved = snapshot.data() ?? <String, dynamic>{};

    final bool announcements =
        saved['announcements'] as bool? ?? true;

    final List<String> categories = List<String>.from(
      saved['jobCategories'] ?? const <String>[],
    );

    final token = await messaging.getToken();

    await settingsRef.set({
      'role': _isAdmin ? 'admin' : 'candidate',
      'updatedAt': FieldValue.serverTimestamp(),

      if (token != null)
        'tokens': FieldValue.arrayUnion([token]),

      if (!snapshot.exists)
        'announcements': true,

      if (!snapshot.exists)
        'jobCategories': <String>[],

    }, SetOptions(merge: true));

    // -------------------------------------------------------------------
    // Topic subscriptions
    // -------------------------------------------------------------------

    if (_isAdmin) {
      // Admin notification subscriptions.
      await _unsubscribe(NotificationTopics.allUsers);

      for (final category in JobCategories.all) {
        await _unsubscribe(
          NotificationTopics.forCategory(category),
        );
      }

      await _subscribe(NotificationTopics.admins);

    } else {
      // Job seeker notification subscriptions.
      await _unsubscribe(NotificationTopics.admins);

      if (announcements) {
        await _subscribe(NotificationTopics.allUsers);
      } else {
        await _unsubscribe(NotificationTopics.allUsers);
      }

      for (final category in JobCategories.all) {
        if (categories.contains(category)) {
          await _subscribe(
            NotificationTopics.forCategory(category),
          );
        } else {
          await _unsubscribe(
            NotificationTopics.forCategory(category),
          );
        }
      }
    }
  }

// =====================================================================
// TOKEN REFRESH
// =====================================================================

  Future<void> _onTokenRefresh(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      await _db
          .collection('notification_settings')
          .doc(uid)
          .set({
        'tokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Token refresh save error: $e');
    }
  }

// =====================================================================
// ADMIN ROLE VERIFICATION
// =====================================================================

  Future<bool> _checkIsAdmin(String uid) async {
    try {
      final doc = await _db
          .collection('admins')
          .doc(uid)
          .get();

      if (!doc.exists) return false;

      return doc.data()?['role'] == 'admin';

    } catch (_) {
      return false;
    }
  }

// =====================================================================
// LOGOUT CLEANUP
// =====================================================================

  /// Call this before FirebaseAuth.instance.signOut().
  Future<void> onBeforeLogout() async {
    if (!isSupported) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final messaging = FirebaseMessaging.instance;

      if (uid != null) {
        final ref = _db
            .collection('notification_settings')
            .doc(uid);

        final snapshot = await ref.get();

        final categories = List<String>.from(
          snapshot.data()?['jobCategories'] ??
              const <String>[],
        );

        final token = await messaging.getToken();

        if (token != null) {
          await ref.set({
            'tokens': FieldValue.arrayRemove([token]),
          }, SetOptions(merge: true));
        }

        await _unsubscribe(NotificationTopics.allUsers);
        await _unsubscribe(NotificationTopics.admins);

        for (final category in categories) {
          await _unsubscribe(
            NotificationTopics.forCategory(category),
          );
        }
      }

      // Remove scheduled reminders belonging to the previous user.
      await _local.cancelAll();

    } catch (e) {
      debugPrint('Notification logout cleanup error: $e');
    }

    _currentUid = null;
    _isAdmin = false;
    _adminCheckedUid = null;
  }

// =====================================================================
// TOPIC SUBSCRIPTION HELPERS
// =====================================================================

  Future<void> _subscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);

      debugPrint('FCM SUBSCRIBED SUCCESS: $topic');

    } catch (e) {
      debugPrint('FCM SUBSCRIBE FAILED: $topic -> $e');
    }
  }

  Future<void> _unsubscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);

    } catch (e) {
      debugPrint('Unsubscribe $topic failed: $e');
    }
  }
  // =====================================================================
// SETTINGS SCREEN HELPERS
// =====================================================================

  Future<NotificationPrefs> loadPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    bool announcements = true;
    var categories = <String>{};

    if (uid != null) {
      final snapshot = await _db
          .collection('notification_settings')
          .doc(uid)
          .get();

      final data = snapshot.data();

      announcements = data?['announcements'] as bool? ?? true;

      categories = Set<String>.from(
        data?['jobCategories'] ?? const <String>[],
      );

      if (!_isAdmin) {
        _isAdmin = await _checkIsAdmin(uid);
      }
    }

    return NotificationPrefs(
      announcements: announcements,
      categories: categories,
      isAdmin: _isAdmin,
    );
  }

// =====================================================================
// ANNOUNCEMENT PREFERENCES
// =====================================================================

  Future<void> setAnnouncementsEnabled(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    await _db
        .collection('notification_settings')
        .doc(uid)
        .set({
      'announcements': enabled,
    }, SetOptions(merge: true));

    if (!isSupported) return;

    if (enabled) {
      await _subscribe(NotificationTopics.allUsers);
    } else {
      await _unsubscribe(NotificationTopics.allUsers);
    }
  }

// =====================================================================
// JOB CATEGORY SUBSCRIPTIONS
// =====================================================================

  Future<void> setCategorySubscribed(
      String category,
      bool subscribed,
      ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    await _db
        .collection('notification_settings')
        .doc(uid)
        .set({
      'jobCategories': subscribed
          ? FieldValue.arrayUnion([category])
          : FieldValue.arrayRemove([category]),
    }, SetOptions(merge: true));

    if (!isSupported) return;

    final topic = NotificationTopics.forCategory(category);

    if (subscribed) {
      await _subscribe(topic);
    } else {
      await _unsubscribe(topic);
    }
  }

// =====================================================================
// NOTIFICATION PERMISSIONS
// =====================================================================

  Future<bool> areNotificationsAllowed() async {
    if (!isSupported) return false;

    final settings = await FirebaseMessaging.instance
        .getNotificationSettings();

    return settings.authorizationStatus ==
        AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional;
  }

  Future<void> requestPermission() async {
    if (!isSupported) return;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

// =====================================================================
// DEVICE TOKEN
// =====================================================================

  Future<String?> getDeviceToken() async {
    if (!isSupported) return null;

    return FirebaseMessaging.instance.getToken();
  }
  // =====================================================================
// TEST NOTIFICATIONS
// =====================================================================

  Future<String> sendTestPush({int delaySeconds = 0}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return 'Please login before testing notifications.';
      }

      if (!isSupported) {
        return 'Test notifications are supported on Android and iOS.';
      }

      final token = await getDeviceToken();

      if (token == null || token.isEmpty) {
        return 'No FCM token yet. Test on a real Android/iOS device.';
      }

      if (delaySeconds > 0) {
        await Future.delayed(
          Duration(seconds: delaySeconds),
        );
      }

      // Save the latest device token in Firestore.
      await _db
          .collection('notification_settings')
          .doc(user.uid)
          .set({
        'tokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return 'FCM token is ready. Use Firebase Console to send a test push.';

    } catch (e) {
      debugPrint('Test push error: $e');

      return 'Failed to prepare test notification. Please try again.';
    }
  }

  /// Tests local notification display on this device.
  Future<void> sendTestLocalNotification() async {
    await showLocal(
      title: 'CareerWise Test Notification',
      body: 'Your local notification is working!',
      data: {
        'type': NotificationTypes.announcement,
      },
    );
  }
  // =====================================================================
// SHOWING LOCAL NOTIFICATIONS
// =====================================================================

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
      'USER FCM RECEIVED: ${message.notification?.title}',
    );

    final title =
        message.notification?.title ?? message.data['title'];

    final body =
        message.notification?.body ?? message.data['body'];

    if (title == null && body == null) return;

    // Android does not automatically display foreground FCM notifications.
    // iOS already displays banners for notification messages.
    if (defaultTargetPlatform == TargetPlatform.android ||
        message.notification == null) {
      showLocal(
        title: title ?? 'CareerWise',
        body: body ?? '',
        data: message.data,
      );
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    int? id,
  }) async {
    if (!isSupported) return;

    try {
      await _local.show(
        id: id ??
            DateTime.now()
                .millisecondsSinceEpoch
                .remainder(0x7fffffff),
        title: title,
        body: body,
        notificationDetails: _details,
        payload: jsonEncode(data),
      );

    } catch (e) {
      debugPrint('Local notification error: $e');
    }
  }

  // =====================================================================
  // BACKGROUND NOTIFICATIONS
  // =====================================================================

  /// Displays data-only messages received in the background.
  static Future<void> showDataOnlyMessageInBackground(
      RemoteMessage message,
      ) async {
    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      settings: _initSettings,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await plugin.show(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .remainder(0x7fffffff),
      title: message.data['title'],
      body: message.data['body'],
      notificationDetails: _details,
      payload: jsonEncode(message.data),
    );
  }
  // =====================================================================
// NAVIGATION
// =====================================================================

  void _handlePayloadString(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        unawaited(_navigateWhenReady(decoded));
      }
    } catch (e) {
      debugPrint('Bad notification payload: $e');
    }
  }

// =====================================================================
// WAIT FOR AUTHENTICATION AND NAVIGATOR
// =====================================================================

  Future<void> _navigateWhenReady(
      Map<String, dynamic> data,
      ) async {
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    if (FirebaseAuth.instance.currentUser == null) return;

    for (
    var i = 0;
    i < 60 && appNavigatorKey.currentState == null;
    i++
    ) {
      await Future.delayed(
        const Duration(milliseconds: 100),
      );
    }

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) return;

    // Allow AuthGate to build the home or dashboard screen.
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    await _route(navigator, data);
  }

// =====================================================================
// NOTIFICATION SCREEN ROUTING
// =====================================================================

  Future<void> _route(
      NavigatorState navigator,
      Map<String, dynamic> data,
      ) async {
    final type = data['type']?.toString();

    switch (type) {
    // ---------------------------------------------------------------
    // JOB SEEKER
    // ---------------------------------------------------------------

      case NotificationTypes.applicationSubmitted:
      case NotificationTypes.applicationStatus:
      case NotificationTypes.interviewReminder:

        navigator.push(
          MaterialPageRoute(
            builder: (_) => const MyApplicationsScreen(),
          ),
        );

        break;

      case NotificationTypes.profileIncomplete:

        navigator.push(
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );

        break;

    // ---------------------------------------------------------------
    // JOB DETAILS
    // ---------------------------------------------------------------

      case NotificationTypes.newJob:
      case NotificationTypes.jobUpdated:

        final jobId = data['jobId']?.toString() ?? '';

        if (jobId.isEmpty) return;

        final doc = await _db
            .collection('jobs')
            .doc(jobId)
            .get();

        final jobData = doc.data();

        if (!doc.exists || jobData == null) return;

        navigator.push(
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(
              job: Job.fromFirestore(
                doc.id,
                jobData,
              ),
            ),
          ),
        );

        break;

    // ---------------------------------------------------------------
    // EMPLOYER / ADMIN
    // ---------------------------------------------------------------

      case NotificationTypes.newApplication:
      case NotificationTypes.cancelRequest:
      case NotificationTypes.flaggedPost:
      case NotificationTypes.jobApproved:
      case NotificationTypes.jobRejected:

        navigator.popUntil(
              (route) => route.isFirst,
        );

        break;

    // ---------------------------------------------------------------
    // CHAT
    // ---------------------------------------------------------------

      case NotificationTypes.chatMessage:

      // TODO: Integrate ChatScreen navigation using
      // data['chatId'] and data['senderName'].

        navigator.popUntil(
              (route) => route.isFirst,
        );

        break;

    // ---------------------------------------------------------------
    // ANNOUNCEMENTS AND UNKNOWN TYPES
    // ---------------------------------------------------------------

      default:
        break;
    }
  }
}