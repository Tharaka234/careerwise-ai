import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'notification_types.dart';

// =======================================================================
// GLOBALS
// =======================================================================

/// Used by MaterialApp so notifications can open screens without a
/// BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey =
GlobalKey<NavigatorState>();

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
}