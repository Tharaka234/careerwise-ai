import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'package:careerwise-ai/firebase_options.dart';

import 'notification_types.dart';
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

  // =====================================================================
  // INIT
  // =====================================================================

  Future<void> init() async {
    if (_initialized || !isSupported) return;

    tzdata.initializeTimeZones();

    // Initialize local notifications.
    await _local.initialize(
      settings: _initSettings,
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

    _initialized = true;
  }

  // =====================================================================
  // BACKGROUND NOTIFICATIONS
  // =====================================================================

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
    );
  }
}