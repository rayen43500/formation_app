import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjoutQuizPage extends StatefulWidget {
  final String coursId;

  AjoutQuizPage({required this.coursId});

  @override
  _AjoutQuizPageState createState() => _AjoutQuizPageState();
}

class _AjoutQuizPageState extends State<AjoutQuizPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titreQuizController = TextEditingController(); // Ajout du controller titre
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _answerControllers =
  List.generate(4, (_) => TextEditingController());
  List<int> _correctAnswers = [];

  final List<Map<String, dynamic>> _questions = [];

  int? _editingIndex;

  final Color skillBridgeBlueGray = Color(0xFF2A4D69);

  void _ajouterOuModifierQuestion() {
    if (_formKey.currentState!.validate() && _correctAnswers.isNotEmpty) {
      List<String> answers =
      _answerControllers.map((controller) => controller.text.trim()).toList();

      final questionData = {
        'question': _questionController.text.trim(),
        'answers': answers,
        'correctAnswerIndexes': List.from(_correctAnswers),
      };

      setState(() {
        if (_editingIndex == null) {
          if (_questions.length >= 30) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Le quiz ne peut pas dépasser 30 questions')),
            );
            return;
          }
          _questions.add(questionData);
        } else {
          _questions[_editingIndex!] = questionData;
          _editingIndex = null;
        }
        _viderFormulaire();
      });
    } else if (_correctAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner au moins une bonne réponse')),
      );
    }
  }

  void _chargerQuestionPourEdition(int index) {
    final q = _questions[index];
    _questionController.text = q['question'];
    List answers = q['answers'];
    for (int i = 0; i < 4; i++) {
      _answerControllers[i].text = i < answers.length ? answers[i] : '';
    }
    _correctAnswers = List<int>.from(q['correctAnswerIndexes']);
    _editingIndex = index;
    setState(() {});
  }

  void _supprimerQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      if (_editingIndex == index) {
        _viderFormulaire();
        _editingIndex = null;
      } else if (_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });
  }

  void _viderFormulaire() {
    _questionController.clear();
    _answerControllers.forEach((c) => c.clear());
    _correctAnswers.clear();
  }

  Future<void> _sauvegarderQuiz() async {
    if (_titreQuizController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez saisir le titre du quiz')),
      );
      return;
    }

    if (_questions.length < 4 || _questions.length > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le quiz doit contenir entre 4 et 30 questions')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('quiz').add({
        'titreQuiz': _titreQuizController.text.trim(),
        'coursId': widget.coursId,
        'questions': _questions,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz ajouté')),
      );

      // Retourner à la page précédente (Accueil formateur)
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout du quiz : $e')),
      );
    }
  }


  Widget _buildQuestionPreview(int index) {
    final q = _questions[index];
    final List<String> answers = List<String>.from(q['answers']);
    final List<int> correctIndexes = List<int>.from(q['correctAnswerIndexes']);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Q${index + 1} : ${q['question']}",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ...List.generate(answers.length, (i) {
              final isCorrect = correctIndexes.contains(i);
              return Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(child: Text(answers[i])),
                ],
              );
            }),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _chargerQuestionPourEdition(index),
                  icon: Icon(Icons.edit, color: skillBridgeBlueGray),
                  label: Text('Modifier', style: TextStyle(color: skillBridgeBlueGray)),
                ),
                TextButton.icon(
                  onPressed: () => _supprimerQuestion(index),
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la question' : 'Ajouter une question'),
        backgroundColor: Color(0xFF9DAFCB),
      ),
      backgroundColor: Color(0xFF9DAFCB),
      bottomNavigationBar: Container(
        color: Color(0xFF9DAFCB),
        padding: EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: _questions.length >= 4 ? _sauvegarderQuiz : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text(
            'Ajouter le quiz complet',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.only(bottom: 80),
            children: [
              // Champ titre du quiz ajouté ici sans changer la structure
              TextFormField(
                controller: _titreQuizController,
                decoration: InputDecoration(
                  labelText: 'Titre du quiz',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir le titre du quiz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Il faut ajouter au moins 4 questions.',
                      style: TextStyle(color: Colors.black45, fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Question ${isEditing ? (_editingIndex! + 1) : (_questions.length + 1)}/30",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(labelText: 'Question'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir la question';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ...List.generate(4, (index) {
                return CheckboxListTile(
                  title: TextFormField(
                    controller: _answerControllers[index],
                    decoration: InputDecoration(labelText: 'Réponse ${index + 1}'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir la réponse ${index + 1}';
                      }
                      return null;
                    },
                  ),
                  value: _correctAnswers.contains(index),
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        if (!_correctAnswers.contains(index)) {
                          _correctAnswers.add(index);
                        }
                      } else {
                        _correctAnswers.remove(index);
                      }
                    });
                  },
                );
              }),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _ajouterOuModifierQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      isEditing ? 'Modifier la question' : 'Ajouter cette question',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Questions ajoutées : ${_questions.length}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ...List.generate(_questions.length, (index) => _buildQuestionPreview(index)),
            ],
          ),
        ),
      ),
    );
  }
}