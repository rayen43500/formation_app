import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mesCoursEtud.dart';
import 'profilEtud.dart';
import 'paiement.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comptformateur.dart';

class AccueilEtudiantPage extends StatefulWidget {
  @override
  _AccueilEtudiantPageState createState() => _AccueilEtudiantPageState();
}

class _AccueilEtudiantPageState extends State<AccueilEtudiantPage> {
  String selectedCategory = 'Tous';
  String searchText = '';
  int _selectedIndex = 0;
  List<QueryDocumentSnapshot> categoriesList = [];

  final Color backgroundColor = Color(0xFF9FB0CC);

  @override
  void initState() {
    super.initState();
    _loadInitialCategory();
  }

  Future<void> addParticipantsField() async {
    final coursesSnapshot = await FirebaseFirestore.instance.collection('courses').get();

    for (var doc in coursesSnapshot.docs) {
      final courseData = doc.data() as Map<String, dynamic>;

      // Vérifier si le champ 'participants' existe déjà
      if (!courseData.containsKey('participants')) {
        // Si le champ 'participants' n'existe pas, l'ajouter avec la valeur initiale de 0
        await doc.reference.update({
          'participants': 0,
        });
      }
    }
  }

  Future<void> _loadInitialCategory() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        categoriesList = snapshot.docs;
        selectedCategory = 'Tous';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MesCoursEtudPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un cours...',
                    hintStyle: const TextStyle(
                        fontFamily: 'Comic Sans MS', color: Colors.black54),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Text(
                  'Catégories:',
                  style: TextStyle(
                    fontFamily: 'Comic Sans MS',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 8.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selectedCategory = 'Tous';
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                          selectedCategory == 'Tous' ? Colors.grey : Colors.white38,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
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
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text('Erreur de chargement'));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final categories = snapshot.data!.docs;
                        return Row(
                          children: categories.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final categoryName = data['nom'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedCategory = categoryName;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedCategory == categoryName
                                      ? Colors.grey
                                      : Colors.white38,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontFamily: 'Comic Sans MS',
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: selectedCategory == 'Tous'
                      ? FirebaseFirestore.instance
                      .collection('courses')
                      .where('status', isEqualTo: 'Validé')
                      .snapshots()
                      : FirebaseFirestore.instance
                      .collection('courses')
                      .where('status', isEqualTo: 'Validé')
                      .where('category', isEqualTo: selectedCategory)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final allCourses = snapshot.data!.docs;
                    final filteredCourses = allCourses.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = data['title']?.toLowerCase() ?? '';
                      final instructor = data['instructorName']?.toLowerCase() ?? '';
                      return title.contains(searchText.toLowerCase()) ||
                          instructor.contains(searchText.toLowerCase());
                    }).toList();


                    if (filteredCourses.isEmpty) {
                      return const Center(
                        child: Text('Aucun cours trouvé.',
                            style: TextStyle(color: Colors.white)),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final courseDoc = filteredCourses[index];
                        final data = courseDoc.data() as Map<String, dynamic>;

                        final title = data['title'] ?? 'Sans titre';
                        final instructor = data['instructorName'] ?? 'Instructeur inconnu';
                        final instructorId = data['instructorId'] ?? '';
                        final rating = data['rating'] ?? 0;
                        final price = (data['price'] ?? 0).toDouble();
                        final userId = FirebaseAuth.instance.currentUser?.uid;

                        return GestureDetector(
                          onTap: () {

                          },
                          child: Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontFamily: 'Comic Sans MS',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          final instructorSnapshot = await FirebaseFirestore.instance
                                              .collection('formateurs') // ou 'users' selon ta collection
                                              .doc(instructorId)
                                              .get();

                                          if (instructorSnapshot.exists) {
                                            final formateurData = instructorSnapshot.data()!;

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CompteForm(
                                                  formateurId: instructorId,
                                                  formData: formateurData,
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Gérer le cas où le formateur n'existe pas
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("Formateur non trouvé")),
                                            );
                                          }
                                        },
                                        child: Text(
                                          instructor,
                                          style: const TextStyle(
                                            fontFamily: 'Comic Sans MS',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < rating ? Icons.star : Icons.star_border,
                                            color: i < rating ? Color(0xFFFBC02D) : Colors.grey,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Nombre de participants : ${data['participants'] ?? 0}",
                                    style: const TextStyle(
                                      fontFamily: 'Comic Sans MS',
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.center,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaiementPage(
                                              courseData: data,
                                              originalCourseId: courseDoc.id, // <-- Correction ici
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                      ),
                                      child: Text(
                                        'Acheter le cours (${price.toStringAsFixed(2)} DT)',
                                        style: const TextStyle(
                                          fontFamily: 'Comic Sans MS',
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(fontFamily: 'Comic Sans MS'),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Comic Sans MS'),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Mes Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
