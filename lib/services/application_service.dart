import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

/// A readable error that screens can show to the user.
class ApplicationException implements Exception {
  ApplicationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cancellation workflow for job applications.
///
///  1. The applicant calls [requestCancellation]  -> the admin is notified.
///     Nothing is cancelled yet; the request is stored as `cancelRequest`.
///  2. The admin calls [decideCancellation]       -> the applicant is notified.
///     Approve -> status becomes "Cancelled". Decline -> application stays.
///
/// IMPORTANT: this runs inside the app, so Firestore Security Rules are the
/// only real protection. See the rules in README_STANDALONE.md.
class ApplicationService {
  ApplicationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Set<String> _finalStatuses = {
    'hired',
    'accepted',
    'rejected',
    'cancelled',
  };

  static String _normalize(Object? status) =>
      status?.toString().trim().toLowerCase() ?? '';

  static ApplicationException _friendly(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return ApplicationException(
        'Not allowed by Firestore rules. Update the rules for the '
            'applications collection (see README_STANDALONE.md).',
      );
    }
    return ApplicationException('Something went wrong. Please try again.');
  }
}