import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:careerwise_sample/model/job.dart';

class JobService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  // Get All Jobs
  Stream<List<Job>> getJobs() {
    return _firestore
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromFirestore(
          doc.id,
          doc.data(),
        );
      }).toList();
    });
  }
  // ==========================================================
// Get Jobs Related to Career
// ==========================================================

  Stream<List<Job>> getRelatedJobs(String career) {
    return getJobs().map((jobs) {
      return _filterJobsByCareer(
        jobs,
        career,
      );
    });
  }
  // ==========================================================
// Career Matching
// ==========================================================

  List<Job> _filterJobsByCareer(
      List<Job> jobs,
      String career,
      ) {
    final keywords = _getCareerKeywords(career);

    return jobs.where((job) {
      final searchableText = [
        job.title,
        job.company,
        job.description,
        job.jobType,
      ].join(' ').toLowerCase();

      return keywords.any(
            (keyword) => searchableText.contains(
          keyword.toLowerCase(),
        ),
      );
    }).toList();
  }
  // ==========================================================
// Career Keywords / Related Titles
// ==========================================================

  List<String> _getCareerKeywords(String career) {
    final normalized = career.toLowerCase().trim();

    if (normalized.isEmpty) {
      return [];
    }

    // Generic fallback
    return [
      normalized,
    ];
  }
}