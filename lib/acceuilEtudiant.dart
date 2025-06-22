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
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Text(
                  "Découvrez nos cours",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F51B5),
                  ),
                ),
              ),
              // Barre de recherche
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un cours...',
                    hintStyle: TextStyle(color: Colors.black54),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF3F51B5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Color(0xFF3F51B5), width: 1),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                ),
              ),
              // Titre des catégories
              Padding(
                padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  'Catégories:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              // Liste des catégories
              Container(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 4.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategory = 'Tous';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategory == 'Tous' 
                              ? Color(0xFF3F51B5) 
                              : Colors.white,
                          foregroundColor: selectedCategory == 'Tous'
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                              color: selectedCategory == 'Tous'
                                  ? Colors.transparent
                                  : Colors.grey.shade300,
                            ),
                          ),
                          elevation: selectedCategory == 'Tous' ? 2 : 0,
                        ),
                        child: Text(
                          'Tous',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedCategory = categoryName;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: selectedCategory == categoryName
                                      ? Color(0xFF3F51B5)
                                      : Colors.white,
                                  foregroundColor: selectedCategory == categoryName
                                      ? Colors.white
                                      : Colors.black87,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    side: BorderSide(
                                      color: selectedCategory == categoryName
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  elevation: selectedCategory == categoryName ? 2 : 0,
                                ),
                                child: Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
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
              SizedBox(height: 16),
              // Liste des cours
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
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Chargement des cours...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF3F51B5),
                              ),
                            ),
                          ],
                        ),
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
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun cours trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Essayez de modifier vos critères de recherche',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
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
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Color(0xFF3F51B5),
                                      ),
                                      SizedBox(width: 4),
                                      InkWell(
                                        onTap: () async {
                                          final instructorSnapshot = await FirebaseFirestore.instance
                                              .collection('formateurs')
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
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Formateur non trouvé"),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          instructor,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF3F51B5),
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < rating ? Icons.star : Icons.star_border,
                                            color: i < rating ? Color(0xFFFBC02D) : Colors.grey,
                                            size: 18,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "${data['participants'] ?? 0} participants",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        "${price.toStringAsFixed(2)} DT",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3F51B5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaiementPage(
                                              courseData: data,
                                              originalCourseId: courseDoc.id,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Acheter',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Color(0xFF3F51B5),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
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
      ),
    );
  }
}
