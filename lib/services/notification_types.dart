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
class NotificationTypes {
  NotificationTypes._();

  // ---- Job seeker ---------------------------------------------------
  static const String applicationSubmitted = 'application_submitted';
  static const String applicationStatus = 'application_status';
  static const String interviewReminder = 'interview_reminder';
  static const String profileIncomplete = 'profile_incomplete';
  static const String newJob = 'new_job';
  static const String jobUpdated = 'job_updated';
  static const String jobDeleted = 'job_deleted';

  // ---- Employer / publisher -----------------------------------------
  static const String newApplication = 'new_application';
  static const String cancelRequest = 'cancel_request';
  static const String jobApproved = 'job_approved';
  static const String jobRejected = 'job_rejected';

  // ---- Chat (both directions) ---------------------------------------
  static const String chatMessage = 'chat_message';

  // ---- Admin --------------------------------------------------------
  static const String flaggedPost = 'flagged_post';

  // ---- Everyone -----------------------------------------------------
  static const String announcement = 'announcement';
}