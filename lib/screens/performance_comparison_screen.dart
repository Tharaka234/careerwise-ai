import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_profile_screen.dart';

class PerformanceComparisonScreen extends StatefulWidget {
  final String originalInterviewId, reassessmentInterviewId;
  const PerformanceComparisonScreen({super.key, required this.originalInterviewId, required this.reassessmentInterviewId});
  @override
  State<PerformanceComparisonScreen> createState() => _PerformanceComparisonScreenState();
}
class _PerformanceComparisonScreenState extends State<PerformanceComparisonScreen> {
  late Future<List<Map<String,dynamic>>> _future;
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<List<Map<String,dynamic>>> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Please sign in.');
    final collection = FirebaseFirestore.instance.collection('mock_interviews');
    final docs = await Future.wait([collection.doc(widget.originalInterviewId).get(), collection.doc(widget.reassessmentInterviewId).get()]);
    final a = docs[0].data(), b = docs[1].data();
    if (a == null || b == null || a['userId'] != uid || b['userId'] != uid || b['originalInterviewId'] != widget.originalInterviewId || a['jobTitle'] != b['jobTitle']) throw Exception('Comparison unavailable.');
    return [a,b];
  }
  int score(Map<String,dynamic> d) => (d['score'] as num).toInt().clamp(0,100).toInt();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
      valueListenable: AdminThemeManager.isDarkMode,
      builder: (context, dark, _) {
        final bg = Color(dark ? 0xFF0A140F : 0xFFF0FDF4), card = dark ? const Color(0xFF13231B) : Colors.white;
        final ink = Color(dark ? 0xFFF0FDF4 : 0xFF0F241B), muted = Color(dark ? 0xFFA7C1B3 : 0xFF4B6354), green = Color(dark ? 0xFF34D399 : 0xFF047857), border = Color(dark ? 0xFF1E382A : 0xFFD1FAE5);
        Widget panel(Widget child) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)), child: child);
        Widget label(String text) => Text(text, style: TextStyle(color: muted, fontSize: 13));
        Widget bar(String title, int value, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children:[Expanded(child: label(title)), Text('$value / 100', style: TextStyle(color: ink, fontWeight: FontWeight.bold))]), const SizedBox(height: 8), LinearProgressIndicator(value: value/100, minHeight: 9, color: color, backgroundColor: border, borderRadius: BorderRadius.circular(8))]);
        Widget feedback(String title, Map<String,dynamic> data, {required bool reassessment}) {
          final raw = data['feedback'];
          final f = raw is Map ? raw : <String, dynamic>{};
          final accent = reassessment ? green : muted;
          Widget section(String key, String heading, IconData icon, Color color) {
            final values = f[key];
            if (values is! List) return const SizedBox.shrink();
            final items = values.map((v) => v.toString().trim()).where((v) => v.isNotEmpty).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(icon, color: color, size: 19), const SizedBox(width: 8), Expanded(child: Text(heading, style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 14)))]),
                const SizedBox(height: 10),
                for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 7, color: color)), const SizedBox(width: 10), Expanded(child: Text(item, style: TextStyle(color: muted, fontSize: 13, height: 1.5)))])),
              ]),
            );
          }
          return panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(15)), child: Icon(reassessment ? Icons.insights_rounded : Icons.assignment_outlined, color: accent, size: 25)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(reassessment ? 'AFTER ROADMAP' : 'BEFORE ROADMAP', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)), const SizedBox(height: 4), Text(title, style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800))])),
              Text('${score(data)}%', style: TextStyle(color: accent, fontSize: 23, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 18),
            Container(width: double.infinity, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: dark ? const Color(0xFF0F1E17) : const Color(0xFFF3F8F5), borderRadius: BorderRadius.circular(14), border: Border.all(color: border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AI assessment summary', style: TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 8), Text('${f['summary'] ?? 'No summary available.'}', style: TextStyle(color: muted, fontSize: 14, height: 1.65))])),
            section('strengths', 'Key strengths', Icons.check_circle_outline_rounded, green),
            section('improvements', 'Areas to improve', Icons.track_changes_rounded, dark ? Colors.orangeAccent : Colors.deepOrange),
            section('tips', 'Recommended next steps', Icons.lightbulb_outline_rounded, green),
          ]));
        }
        return Scaffold(backgroundColor: bg, appBar: AppBar(backgroundColor: bg, surfaceTintColor: Colors.transparent, iconTheme: IconThemeData(color: ink), title: Text('Performance Comparison', style: TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w800))), body: FutureBuilder<List<Map<String,dynamic>>>(future: _future, builder: (context,snapshot) {
          if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children:[Text('Unable to load comparison', style: TextStyle(color: ink)), TextButton(onPressed: () => setState(() => _future = _load()), child: const Text('Try again'))]));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: green));
          final a = snapshot.data![0], b = snapshot.data![1], before = score(a), after = score(b), delta = after-before;
          final change = delta > 0 ? green : delta < 0 ? (dark ? Colors.orangeAccent : Colors.deepOrange) : muted;
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: ListView(padding: const EdgeInsets.all(18), children:[
            Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFF066B50),Color(0xFF059669),Color(0xFF10B981)]), borderRadius: BorderRadius.circular(28)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[const Icon(Icons.insights_rounded,color: Colors.white,size: 32),const SizedBox(height: 18),const Text('Your interview progress',style: TextStyle(color: Colors.white,fontSize: 26,fontWeight: FontWeight.w800)),const SizedBox(height: 8),Text('${a['jobTitle'] ?? ''}',style: const TextStyle(color: Colors.white))])),
            const SizedBox(height: 18), panel(Column(children:[Row(children:[Expanded(child: Column(children:[label('Before roadmap'),Text('$before%',style: TextStyle(color: ink,fontSize: 30,fontWeight: FontWeight.w900))])),Expanded(child: Column(children:[label('After roadmap'),Text('$after%',style: TextStyle(color: green,fontSize: 30,fontWeight: FontWeight.w900))]))]),const SizedBox(height: 20),Text('${delta>0?'+':''}$delta pp',style: TextStyle(color: change,fontSize: 32,fontWeight: FontWeight.w900)),label(delta>0?'Higher practice score':delta<0?'Lower practice score':'No score change'),const SizedBox(height: 20),bar('Initial interview',before,muted),const SizedBox(height: 16),bar('Reassessment',after,green)])),
            const SizedBox(height: 16),feedback('Initial feedback',a,reassessment: false),const SizedBox(height: 16),feedback('Reassessment feedback',b,reassessment: true),const SizedBox(height: 16),panel(label('Both attempts use the original questions. AI scores are practice estimates; changes may reflect familiarity with questions or scoring variability, not necessarily the effect of the roadmap.')),
          ])));
        }));
      });
}
