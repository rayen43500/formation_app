import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GestQuizPage extends StatefulWidget {
  @override
  _GestQuizPageState createState() => _GestQuizPageState();
}

class _GestQuizPageState extends State<GestQuizPage> {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? editingQuizId;

  // 🔁 Affiche la boîte de dialogue pour ajouter ou modifier un quiz
  Future<void> _showQuizDialog({DocumentSnapshot? quiz}) {
    if (quiz != null) {
      _titleController.text = quiz['title'];
      _descriptionController.text = quiz['description'];
      editingQuizId = quiz.id;
    } else {
      _titleController.clear();
      _descriptionController.clear();
      editingQuizId = null;
    }

    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(quiz == null ? 'Ajouter un quiz' : 'Modifier le quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Titre du quiz'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text.trim();
              final description = _descriptionController.text.trim();

              if (title.isEmpty || description.isEmpty) return;

              if (editingQuizId == null) {
                await _firestore.collection('quizzes').add({
                  'title': title,
                  'description': description,
                  'createdAt': Timestamp.now(),
                  'status': 'En attente',
                });
              } else {
                await _firestore.collection('quizzes').doc(editingQuizId).update({
                  'title': title,
                  'description': description,
                });
              }

              Navigator.pop(context);
            },
            child: Text(quiz == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  // ❌ Supprimer un quiz
  Future<void> _deleteQuiz(String quizId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous supprimer ce quiz ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Supprimer')),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('quizzes').doc(quizId).delete();
    }
  }

  // 🔄 Mettre à jour le statut du quiz
  Future<void> _updateQuizStatus(String quizId, String status) async {
    await _firestore.collection('quizzes').doc(quizId).update({'status': status});
  }

  // 🎨 Couleurs selon le statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Validé':
        return Colors.green;
      case 'Refusé':
        return Colors.red;
      case 'En attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // 🖼️ Affichage principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Quiz'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('quizzes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erreur de chargement'));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final quizzes = snapshot.data!.docs;

          if (quizzes.isEmpty) return Center(child: Text('Aucun quiz trouvé.'));

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              final status = quiz['status'];

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['title'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(quiz['description']),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Statut : ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          ElevatedButton(
                            onPressed: () => _updateQuizStatus(quiz.id, 'Validé'),
                            child: Text('Valider'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                          ElevatedButton(
                            onPressed: () => _updateQuizStatus(quiz.id, 'En attente'),
                            child: Text('En attente'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                          ElevatedButton(
                            onPressed: () => _updateQuizStatus(quiz.id, 'Refusé'),
                            child: Text('Refuser'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showQuizDialog(quiz: quiz),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteQuiz(quiz.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuizDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}
