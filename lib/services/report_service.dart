import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

/// "Report post" feature. Saves the report and alerts every admin.
class ReportService {
  ReportService._();

  static const List<String> reasons = [
    'Fake or scam job',
    'Misleading information',
    'Inappropriate content',
    'Duplicate post',
    'Other',
  ];
}