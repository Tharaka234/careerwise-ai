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

  // ==========================================================
// Career Keywords / Related Titles
// ==========================================================

  List<String> _getCareerKeywords(String career) {
    final normalized = career.toLowerCase().trim();

    if (normalized.isEmpty) {
      return [];
    }

    // Software Engineering
    if (normalized.contains('software engineer') ||
        normalized.contains('software developer')) {
      return [
        'software engineer',
        'software developer',
        'software development',
        'application developer',
        'application engineer',
        'programmer',
        'developer',
      ];
    }

    // Full Stack Development
    if (normalized.contains('full stack')) {
      return [
        'full stack',
        'full-stack',
        'frontend',
        'front end',
        'backend',
        'back end',
        'web developer',
        'web development',
        'software developer',
      ];
    }

    // Mobile Application Development
    if (normalized.contains('mobile') ||
        normalized.contains('flutter') ||
        normalized.contains('android') ||
        normalized.contains('ios')) {
      return [
        'mobile developer',
        'mobile app developer',
        'flutter developer',
        'flutter',
        'android developer',
        'android',
        'ios developer',
        'ios',
        'mobile application',
      ];
    }
    // Data Analysis
    if (normalized.contains('data analyst') ||
        normalized.contains('data analysis')) {
      return [
        'data analyst',
        'data analysis',
        'data analytics',
        'business analyst',
        'sql',
        'python',
        'power bi',
        'tableau',
      ];
    }
    // Data Science and Machine Learning
    if (normalized.contains('data scientist') ||
        normalized.contains('machine learning')) {
      return [
        'data scientist',
        'machine learning',
        'ml engineer',
        'artificial intelligence',
        'ai engineer',
        'data science',
        'python',
      ];
    }
    // Artificial Intelligence
    if (normalized.contains('ai') ||
        normalized.contains('artificial intelligence')) {
      return [
        'ai engineer',
        'artificial intelligence',
        'machine learning',
        'machine learning engineer',
        'data scientist',
        'ai developer',
      ];
    }
    // Cybersecurity
    if (normalized.contains('cybersecurity') ||
        normalized.contains('cyber security')) {
      return [
        'cybersecurity',
        'cyber security',
        'security analyst',
        'security engineer',
        'information security',
        'soc analyst',
      ];
    }

    // Generic fallback
    return [
      normalized,
    ];
  }
}