import 'package:flutter/material.dart';

import '../services/application_service.dart';

const _amber = Color(0xFFD97706);
const _grey = Color(0xFF6B7280);

bool _isFinal(String status) {
  const finals = {'hired', 'accepted', 'rejected', 'cancelled'};
  return finals.contains(status.trim().toLowerCase());
}

/// Shown on the ADMIN application card when the applicant asked to cancel.
/// The admin decides: Approve -> application becomes "Cancelled",
/// Decline -> the application stays active. Either way the applicant is told.
class CancelRequestBanner extends StatefulWidget {
  const CancelRequestBanner({
    super.key,
    required this.applicationId,
    required this.data,
    required this.isDark,
    required this.textColor,
    required this.mutedColor,
  });

  final String applicationId;
  final Map<String, dynamic> data;
  final bool isDark;
  final Color textColor;
  final Color mutedColor;

  @override
  State<CancelRequestBanner> createState() => _CancelRequestBannerState();
}

class _CancelRequestBannerState extends State<CancelRequestBanner> {
  bool _busy = false;
}
