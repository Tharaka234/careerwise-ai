/// Central place for every constant used by the notification system.

class NotificationChannels {
  NotificationChannels._();

  /// Must match the `default_notification_channel_id` value in
  /// android/app/src/main/AndroidManifest.xml

  static const String highImportance =
      'careerwise_high_importance';

  static const String highImportanceName =
      'CareerWise Notifications';

  static const String highImportanceDescription =
      'Application updates, job alerts, messages and announcements.';
}