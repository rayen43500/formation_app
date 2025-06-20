import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DétailQuiz.dart';

class QuizPage extends StatelessWidget {
  final String courseId;

  const QuizPage({Key? key, required this.courseId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9FB0CC), // fond de la page
      appBar: AppBar(
        title: Text('Quiz du cours'),
        backgroundColor: Color(0xFF9FB0CC),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz')
            .where('coursId', isEqualTo: courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucun quiz trouvé pour ce cours.'));
          }

          final quizDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: quizDocs.length,
            itemBuilder: (context, index) {
              final quizData = quizDocs[index].data()! as Map<String, dynamic>;
              final quizTitle = quizData['titreQuiz'] ?? 'Quiz sans titre';
              final quizId = quizDocs[index].id;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white54), // cadre gris clair
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white54,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: ListTile(
                  title: Text(quizTitle),
                  trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailQuizPage(quizId: quizId),
                        ),
                      );
                    }
                ),
              );
            },
          );
        },
      ),
    );
  }
}
