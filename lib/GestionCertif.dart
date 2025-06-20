import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'detail_quiz_page.dart';

class GestionCertificationPage extends StatefulWidget {
  @override
  _GestionCertificationPageState createState() => _GestionCertificationPageState();
}

class _GestionCertificationPageState extends State<GestionCertificationPage> {
  final Color primaryColor = Color(0xFF9DAFCB);
  final uid = FirebaseAuth.instance.currentUser?.uid;

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      color: primaryColor.withOpacity(0.15),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('Cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            flex: 6,
            child: Text('Quiz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String courseName,
    required String quizTitles,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(courseName, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 6,
            child: Text(quizTitles.isNotEmpty ? quizTitles : '—', style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Gestion Certifications'),
          backgroundColor: primaryColor,
        ),
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des quizzes'),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('instructorId', isEqualTo: uid)
            .where('status', isEqualTo: 'Validé')
            .snapshots(),
        builder: (context, courseSnapshot) {
          if (courseSnapshot.hasError) {
            return Center(child: Text('Erreur : ${courseSnapshot.error}'));
          }
          if (!courseSnapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final courses = courseSnapshot.data!.docs;
          if (courses.isEmpty) {
            return Center(child: Text('Aucun cours validé trouvé.'));
          }

          return Column(
            children: [
              _buildTableHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final courseId = course.id;
                    final courseName = course['title'] ?? '—';

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('quiz')
                          .where('coursId', isEqualTo: courseId)
                          .get(),
                      builder: (context, quizSnapshot) {
                        if (quizSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Erreur chargement quiz'),
                          );
                        }
                        if (!quizSnapshot.hasData) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LinearProgressIndicator(color: primaryColor),
                          );
                        }

                        final quizzes = quizSnapshot.data!.docs;

                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: primaryColor.withOpacity(0.3))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(courseName, style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: quizzes.isEmpty
                                      ? [Text('—', style: TextStyle(color: Colors.grey[700]))]
                                      : quizzes.map((q) {
                                    final titre = q['titreQuiz'] ?? '—';
                                    final id = q.id;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetailQuizPage(quizId: id),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text(
                                          titre,
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
