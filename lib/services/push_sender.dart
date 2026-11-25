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
}