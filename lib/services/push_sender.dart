import 'notification_types.dart';
/// Represents the result of a push notification request.
enum PushResult {
  /// FCM accepted the message.
  sent,

  /// The device registration token is no longer valid.
  invalidToken,

  /// Network, permission or payload problem.
  failed,

  /// Push notification service is not configured.
  notConfigured,
}

/// Handles push notification delivery for CareerWise.
class PushSender {
  PushSender._();

  // --------------------------------------------------------------------
// FCM Message Payload
// --------------------------------------------------------------------

  static Map<String, dynamic> _buildMessage({
    String? token,
    String? topic,
    required String title,
    required String body,
    required Map<String, String> data,
    required bool dataOnly,
  }) {
    final payload = <String, String>{
      ...data,
      'title': title,
      'body': body,
    };

    return {
      if (token != null) 'token': token,
      if (topic != null) 'topic': topic,
      if (!dataOnly)
        'notification': {
          'title': title,
          'body': body,
        },
      'data': payload,
      'android': {
        'priority': 'HIGH',
        if (!dataOnly)
          'notification': {
            'channel_id': NotificationChannels.highImportance,
            'sound': 'default',
          },
      },
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {'sound': 'default'},
        },
      },
    };
  }
}