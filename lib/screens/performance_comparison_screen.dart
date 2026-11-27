import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception('Please sign in.');
    }

    final collection =
    FirebaseFirestore.instance.collection('mock_interviews');

    final docs = await Future.wait([
      collection.doc(widget.originalInterviewId).get(),
      collection.doc(widget.reassessmentInterviewId).get(),
    ]);

    final original = docs[0].data();
    final reassessment = docs[1].data();

    if (original == null ||
        reassessment == null ||
        original['userId'] != uid ||
        reassessment['userId'] != uid ||
        reassessment['originalInterviewId'] !=
            widget.originalInterviewId ||
        original['jobTitle'] != reassessment['jobTitle']) {
      throw Exception('Comparison unavailable.');
    }

    return [original, reassessment];
  }

  int score(Map<String, dynamic> data) {
    final value = data['score'];

    if (value is! num) {
      return 0;
    }

    return value.toInt().clamp(0, 100).toInt();
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load comparison'),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _future = _load();
                      });
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final original = snapshot.data![0];
          final reassessment = snapshot.data![1];

          final before = score(original);
          final after = score(reassessment);
          final difference = after - before;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              Text(
                original['jobTitle'] ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [

                          Column(
                            children: [
                              const Text('Before Roadmap'),
                              Text(
                                '$before%',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              const Text('After Roadmap'),
                              Text(
                                '$after%',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        '${difference > 0 ? '+' : ''}$difference pp',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: difference > 0
                              ? Colors.green
                              : difference < 0
                              ? Colors.deepOrange
                              : Colors.grey,
                        ),
                      ),

                      Text(
                        difference > 0
                            ? 'Higher practice score'
                            : difference < 0
                            ? 'Lower practice score'
                            : 'No score change',
                      ),

                      const SizedBox(height: 25),

                      LinearProgressIndicator(
                        value: before / 100,
                        minHeight: 10,
                      ),

                      const SizedBox(height: 15),

                      LinearProgressIndicator(
                        value: after / 100,
                        minHeight: 10,
                        color: Colors.green,
                      ),
                    ],
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