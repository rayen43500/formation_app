import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailQuizPage extends StatefulWidget {
  final String quizId;

  const DetailQuizPage({Key? key, required this.quizId}) : super(key: key);

  @override
  _DetailQuizPageState createState() => _DetailQuizPageState();
}

class _DetailQuizPageState extends State<DetailQuizPage> {
  List<Map<String, dynamic>> questions = [];
  Map<int, Set<int>> userAnswers = {};
  bool submitted = false;
  int score = 0;
  User? currentUser;
  String? mention;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _loadQuizQuestions();
  }

  Future<void> _loadQuizQuestions() async {
    final quizDoc =
    await FirebaseFirestore.instance
        .collection('quiz')
        .doc(widget.quizId)
        .get();
    if (quizDoc.exists) {
      final data = quizDoc.data()!;
      setState(() {
        questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
      });
    }
  }

  void _toggleAnswer(int questionIndex, int answerIndex) {
    if (submitted) return;
    final selected = userAnswers[questionIndex] ?? <int>{};
    setState(() {
      if (selected.contains(answerIndex)) {
        selected.remove(answerIndex);
        if (selected.isEmpty) {
          userAnswers.remove(questionIndex);
        } else {
          userAnswers[questionIndex] = selected;
        }
      } else {
        if (selected.length < 2) {
          selected.add(answerIndex);
          userAnswers[questionIndex] = selected;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'Vous ne pouvez sélectionner que 2 réponses au maximum.')),
          );
        }
      }
    });
  }

  // ... [imports et autres parties inchangées]

  Future<void> _submitAnswers() async {
    if (currentUser == null) return;

    int tempScore = 0;
    for (int i = 0; i < questions.length; i++) {
      final correctIndexes = Set<int>.from(
          questions[i]['correctAnswerIndexes'] ?? []);
      final selectedIndexes = userAnswers[i] ?? {};
      if (correctIndexes.length == selectedIndexes.length &&
          correctIndexes.containsAll(selectedIndexes)) {
        tempScore++;
      }
    }

    setState(() {
      score = tempScore;
      submitted = true;
    });

    final resultRef = FirebaseFirestore.instance
        .collection('Results')
        .where('quizId', isEqualTo: widget.quizId)
        .where('studentId', isEqualTo: currentUser!.uid);

    final snapshot = await resultRef.get();

    final scorePercentDouble = (score / questions.length) * 100;
    final scorePercent = scorePercentDouble.toStringAsFixed(2);
    final remarque = scorePercentDouble >= 50
        ? 'Félicitations, vous avez réussi'
        : 'Malheureusement, à la prochaine fois';

    String mention = '';
    if (scorePercentDouble == 100) {
      mention = 'Excellent';
    } else if (scorePercentDouble >= 80) {
      mention = 'Très bien';
    } else if (scorePercentDouble >= 70) {
      mention = 'Bien';
    } else if (scorePercentDouble >= 50) {
      mention = 'Passable';
    }

    final resultData = {
      'score': scorePercent,
      'remarque': remarque,
      'mention': mention,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (snapshot.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('Results')
          .doc(snapshot.docs.first.id)
          .update(resultData);
    } else {
      await FirebaseFirestore.instance.collection('Results').add({
        'quizId': widget.quizId,
        'studentId': currentUser!.uid,
        ...resultData,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Détail Quiz'), backgroundColor: Color(0xFF9FB0CC)),
      backgroundColor: Color(0xFF9FB0CC),
      body: questions.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Remarque avec icône noire
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.black),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chaque question contient une ou deux bonne(s) réponse(s).',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            ...List.generate(questions.length, (index) {
              final question = questions[index];
              final answers = List<String>.from(question['answers'] ?? []);
              final correctIndexes =
              Set<int>.from(question['correctAnswerIndexes'] ?? []);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${index + 1}: ${question['question']}',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  ...List.generate(answers.length, (answerIndex) {
                    final isSelected =
                        userAnswers[index]?.contains(answerIndex) ?? false;
                    final isCorrect = correctIndexes.contains(answerIndex);
                    Color borderColor = Colors.black;
                    Color fillColor = Colors.transparent;

                    if (submitted && isSelected) {
                      borderColor = isCorrect ? Colors.green : Colors.red;
                      fillColor = borderColor;
                    }

                    return GestureDetector(
                      onTap: () => _toggleAnswer(index, answerIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                Border.all(color: borderColor, width: 2),
                              ),
                              child: isSelected
                                  ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: submitted
                                        ? fillColor
                                        : Colors.black,
                                  ),
                                ),
                              )
                                  : null,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                answers[answerIndex],
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 16),
                ],
              );
            }),
            if (!submitted)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: userAnswers.length == questions.length
                      ? _submitAnswers
                      : null,
                  child: Text('Soumettre',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            if (submitted) ...[
              SizedBox(height: 20),
              Text(
                'Votre score : ${(score / questions.length * 100)
                    .toStringAsFixed(2)}%',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 6),
              Text(
                score / questions.length >= 0.5
                    ? '🎉 Félicitations! vous avez réussi.'
                    : '😔 Malheureusement, à la prochaine fois!',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ]
          ],
        ),
      ),
    );
  }
}