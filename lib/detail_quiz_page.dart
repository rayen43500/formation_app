import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DetailQuizPage extends StatefulWidget {
  final String quizId;

  const DetailQuizPage({required this.quizId});

  @override
  State<DetailQuizPage> createState() => _DetailQuizPageState();
}

class _DetailQuizPageState extends State<DetailQuizPage> {
  List<Map<String, dynamic>> editableQuestions = [];
  bool isLoading = true;
  String titreQuiz = '';
  final Color primaryColor = Color(0xFF9DAFCB);

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    final doc = await FirebaseFirestore.instance.collection('quiz').doc(widget.quizId).get();
    final data = doc.data() as Map<String, dynamic>?;

    if (data != null) {
      titreQuiz = data['titreQuiz'] ?? 'Sans titre';
      final List<dynamic> questions = data['questions'] ?? [];
      editableQuestions = questions.map((q) => Map<String, dynamic>.from(q)).toList();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _updateFirestore() async {
    await FirebaseFirestore.instance.collection('quiz').doc(widget.quizId).update({
      'questions': editableQuestions,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modifications enregistrées')),
    );

    Navigator.pop(context); // Retour automatique à la page précédente
  }

  void _toggleEdit(int index) {
    setState(() {
      editableQuestions[index]['isEditing'] = !(editableQuestions[index]['isEditing'] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('Détail du Quiz'),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Titre : $titreQuiz",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Questions :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: editableQuestions.length,
                itemBuilder: (context, index) {
                  final questionData = editableQuestions[index];
                  final isEditing = questionData['isEditing'] ?? false;
                  final List<dynamic> answers = questionData['answers'] ?? [];
                  final List<dynamic> correctIndexes = questionData['correctAnswerIndexes'] ?? [];

                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: isEditing
                                    ? TextFormField(
                                  initialValue: questionData['question'],
                                  decoration: InputDecoration(labelText: "Question"),
                                  onChanged: (value) =>
                                  editableQuestions[index]['question'] = value,
                                )
                                    : Text(
                                  'Q${index + 1}: ${questionData['question']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _toggleEdit(index),
                                icon: Icon(Icons.edit, color: primaryColor),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ...List.generate(answers.length, (i) {
                            final isCorrect = correctIndexes.contains(i);
                            return Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                  color: isCorrect ? Colors.green : Colors.grey,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: isEditing
                                      ? TextFormField(
                                    initialValue: answers[i].toString(),
                                    onChanged: (value) =>
                                    editableQuestions[index]['answers'][i] = value,
                                  )
                                      : Text(answers[i].toString()),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _updateFirestore,
              icon: Icon(Icons.save),
              label: Text("Enregistrer les modifications"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
