import 'package:flutter/material.dart';
import 'ajoutCours.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profilFormateurform.dart';
import 'package:ly_na/ModificationCour.dart';
import 'ajoutQuiz.dart';
import 'statiCoursAdmin.dart';
import 'VideoCallPage.dart';
import 'video_call_service.dart';

class AccueilFormateur extends StatefulWidget {
  @override
  _AccueilFormateurState createState() => _AccueilFormateurState();
}

class _AccueilFormateurState extends State<AccueilFormateur> {
  String selectedPage = 'Accueil';
  String selectedCategory = 'Tous';

  final Color backgroundColor = Color(0xFF9FB0CC);
  final CollectionReference _categoriesCollection =
  FirebaseFirestore.instance.collection('categories');
  final CollectionReference _coursCollection =
  FirebaseFirestore.instance.collection('courses');
  final String formateurId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String searchText = '';
  
  // Service d'appel vidéo
  final VideoCallService _videoCallService = VideoCallService();

  // Afficher le dialogue de confirmation pour démarrer un appel
  Future<void> _showStartCallDialog(BuildContext context, DocumentSnapshot cours) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Démarrer un appel vidéo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous allez démarrer un appel vidéo pour le cours:'),
              SizedBox(height: 8),
              Text(
                cours['title'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Les étudiants inscrits à ce cours pourront rejoindre la session.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Créer directement le channel name sans passer par le service pour le moment
                String channelName = 'skillbridge_course_${cours.id.replaceAll(' ', '_')}';
                
                // Lancer l'appel immédiatement
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoCallPage(
                      channelName: channelName,
                      isTrainer: true,
                    ),
                  ),
                );
                
                // Enregistrer l'appel dans la base de données en arrière-plan
                try {
                  await _videoCallService.createVideoCall(
                    cours.id,
                    cours['title'],
                  );
                } catch (e) {
                  print("Erreur lors de l'enregistrement de l'appel: $e");
                  // Ne pas bloquer l'interface utilisateur avec cette erreur
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Démarrer l\'appel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedPage != 'Profil') ...[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchText = value.toLowerCase(); // Mise à jour du texte de recherche
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un cours...',
                    hintStyle: TextStyle(fontFamily: 'Comic Sans MS'),
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  'Catégories:',
                  style: TextStyle(
                    fontFamily: 'Comic Sans MS',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 5),
              Container(
                height: 50,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _categoriesCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: Text('Chargement...'));
                    }

                    List<DocumentSnapshot> docs = snapshot.data!.docs;

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = 'Tous';
                              });
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: selectedCategory == 'Tous'
                                  ? Colors.grey
                                  : Colors.white38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Tous',
                              style: TextStyle(
                                fontFamily: 'Comic Sans MS',
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        ...docs.map((doc) {
                          String categoryName = doc['nom'];
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4.0),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedCategory = categoryName;
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                selectedCategory == categoryName
                                    ? Colors.grey
                                    : Colors.white38,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontFamily: 'Comic Sans MS',
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
            Expanded(
              child
                  : selectedPage == 'Accueil'
                  ? _buildCoursValidesAccueil()
                  : ProfileformPage(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedPage == 'Accueil' ? 0 : 1,
        onTap: (index) {
          setState(() {
            selectedPage = index == 0 ? 'Accueil' : 'Profil';
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        selectedLabelStyle: TextStyle(fontFamily: 'Comic Sans MS'),
        unselectedLabelStyle: TextStyle(fontFamily: 'Comic Sans MS'),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      floatingActionButton: selectedPage != 'Profil'
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AjoutCoursPage()),
          );
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.black,
        child: Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildMesCours() {
    return StreamBuilder<QuerySnapshot>(
      stream: _coursCollection
          .where('instructorId', isEqualTo: formateurId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final coursDocs = snapshot.data!.docs;

        if (coursDocs.isEmpty) {
          return Center(child: Text('Aucun cours trouvé.'));
        }

        return ListView.builder(
          itemCount: coursDocs.length,
          itemBuilder: (context, index) {
            var cours = coursDocs[index];
            return buildCourseCard(cours);
          },
        );
      },
    );
  }

  Widget _buildCoursValidesAccueil() {
    return StreamBuilder<QuerySnapshot>(
      stream: _coursCollection
          .where('status', isEqualTo: 'Validé')
          .where('instructorId', isEqualTo: formateurId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        List<QueryDocumentSnapshot> coursDocs = snapshot.data!.docs;

        if (selectedCategory != 'Tous') {
          coursDocs = coursDocs
              .where((doc) => doc['category'] == selectedCategory)
              .toList();
        }

        if (coursDocs.isEmpty) {
          return Center(child: Text('Aucun cours validé trouvé.'));
        }

        return ListView.builder(
          itemCount: coursDocs.length,
          itemBuilder: (context, index) {
            return buildCourseCard(coursDocs[index]);
          },
        );
      },
    );
  }

  Widget buildCourseCard(DocumentSnapshot cours) {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cours['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Comic Sans MS',
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFD6D6D6), // Couleur plus claire
                      child: IconButton(
                        icon: Icon(Icons.video_call, color: Colors.blueGrey, size: 30), // Icône plus grande
                        onPressed: () {
                          // Afficher le dialogue de confirmation pour démarrer l'appel
                          _showStartCallDialog(context, cours);
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  cours['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Comic Sans MS'),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StatiCoursAdminPage(courseId: cours.id),
                        ),
                      );
                    },
                    icon: Icon(Icons.bar_chart),
                    label: Text('Voir statistique'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        ModificationCoursPage(cours: cours),

                    ),
                    );
                  },
                  icon: Icon(Icons.edit),
                  label: Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Confirmation"),
                        content: Text("Supprimer ce cours ?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("Annuler")),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text("Supprimer")),
                        ],
                      ),
                    );

                    if (confirm) {
                      await _coursCollection.doc(cours.id).delete();
                    }
                  },
                  icon: Icon(Icons.delete),
                  label: Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AjoutQuizPage(coursId: cours.id),
                      ),
                    );
                  },
                  icon: Icon(Icons.quiz),
                  label: Text('Ajouter quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
