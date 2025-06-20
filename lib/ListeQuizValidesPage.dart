import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizValidePage extends StatefulWidget {
  const QuizValidePage({Key? key}) : super(key: key);

  @override
  State<QuizValidePage> createState() => _QuizValidePageState();
}

class _QuizValidePageState extends State<QuizValidePage> {
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> resultsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      if (user == null) return;

      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('Results')
          .where('studentId', isEqualTo: user!.uid)
          .get();

      List<Map<String, dynamic>> tempResults = [];

      for (var doc in resultsSnapshot.docs) {
        final data = doc.data();
        final quizId = data['quizId'];

        if (quizId == null) continue;

        final quizDoc = await FirebaseFirestore.instance
            .collection('quiz')
            .doc(quizId)
            .get();

        if (!quizDoc.exists) continue;

        final quizData = quizDoc.data()!;
        final coursId = quizData['coursId'];

        if (coursId == null) continue;

        final courseDoc = await FirebaseFirestore.instance
            .collection('Courses')
            .doc(coursId)
            .get();

        if (!courseDoc.exists) continue;

        final courseData = courseDoc.data()!;

        tempResults.add({
          'courseTitle': courseData['title'] ?? 'Inconnu',
          'quizTitle': quizData['titreQuiz'] ?? 'Inconnu',
          'score': data['score'] ?? '0',
          'mention': data['mention'] ?? '-',
        });
      }

      setState(() {
        resultsList = tempResults;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement résultats : $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Validé'),
        backgroundColor: const Color(0xFF9FB0CC),
      ),
      backgroundColor: const Color(0xFF9FB0CC),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : resultsList.isEmpty
          ? const Center(child: Text("Aucun quiz trouvé."))
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nom du cours')),
            DataColumn(label: Text('Titre quiz')),
            DataColumn(label: Text('Score')),
            DataColumn(label: Text('Mention')),
          ],
          rows: resultsList.map((result) {
            return DataRow(cells: [
              DataCell(Text(result['courseTitle'])),
              DataCell(Text(result['quizTitle'])),
              DataCell(Text('${result['score']}%')),
              DataCell(Text(result['mention'])),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
