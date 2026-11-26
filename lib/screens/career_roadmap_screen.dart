import 'package:flutter/material.dart';

class CareerRoadmapScreen extends StatefulWidget {
  final String interviewId;

  const CareerRoadmapScreen({
    super.key,
    required this.interviewId,
  });

  @override
  State<CareerRoadmapScreen> createState() =>
      _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState
    extends State<CareerRoadmapScreen> {

  // Roadmap generation state.
  bool _generating = false;

  // Roadmap error state.
  String? _error;

  // Track tasks currently being updated.
  final Set<String> _updatingTasks = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Career Roadmap'),
      ),
      body: const Center(
        child: Text('Career Development Roadmap'),
      ),
    );
  }
}