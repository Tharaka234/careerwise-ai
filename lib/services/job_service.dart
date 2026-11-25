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
}