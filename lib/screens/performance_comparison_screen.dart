import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerformanceComparisonScreen extends StatefulWidget {
  final String originalInterviewId;
  final String reassessmentInterviewId;

  const PerformanceComparisonScreen({
    super.key,
    required this.originalInterviewId,
    required this.reassessmentInterviewId,
  });

  @override
  State<PerformanceComparisonScreen> createState() =>
      _PerformanceComparisonScreenState();
}

class _PerformanceComparisonScreenState
    extends State<PerformanceComparisonScreen> {

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final collection =
    FirebaseFirestore.instance.collection('mock_interviews');

    final docs = await Future.wait([
      collection.doc(widget.originalInterviewId).get(),
      collection.doc(widget.reassessmentInterviewId).get(),
    ]);

    final original = docs[0].data();
    final reassessment = docs[1].data();

    if (original == null || reassessment == null) {
      throw Exception('Interview records not found.');
    }

    return [original, reassessment];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Comparison'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load comparison.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final original = snapshot.data![0];
          final reassessment = snapshot.data![1];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              const Text(
                'Your Interview Progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: ListTile(
                  title: const Text('Original Interview'),
                  subtitle: Text(
                    original['jobTitle'] ?? 'Unknown Job',
                  ),
                  trailing: Text(
                    '${original['score'] ?? 0}%',
                  ),
                ),
              ),

              Card(
                child: ListTile(
                  title: const Text('Reassessment Interview'),
                  subtitle: Text(
                    reassessment['jobTitle'] ?? 'Unknown Job',
                  ),
                  trailing: Text(
                    '${reassessment['score'] ?? 0}%',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}