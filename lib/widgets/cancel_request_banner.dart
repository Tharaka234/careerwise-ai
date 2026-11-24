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

  Future<void> _decide(bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve cancellation?' : 'Decline request?'),
        content: Text(
          approve
              ? 'The application will be marked as Cancelled and the applicant will be notified.'
              : 'The application stays active and the applicant will be notified that the request was declined.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  approve ? const Color(0xFF059669) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Yes, approve' : 'Yes, decline'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    String message;
    var failed = false;

    try {
      await ApplicationService.decideCancellation(
        applicationId: widget.applicationId,
        approve: approve,
      );
      message = approve
          ? 'Cancellation approved. The applicant was notified.'
          : 'Request declined. The applicant was notified.';
    } on ApplicationException catch (e) {
      message = e.message;
      failed = true;
    } catch (_) {
      message = 'Could not save your decision. Please try again.';
      failed = true;
    }

    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            failed ? const Color(0xFFDC2626) : const Color(0xFF10B981),
      ),
    );
  }
}
