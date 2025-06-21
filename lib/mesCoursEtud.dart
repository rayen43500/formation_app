import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'acceuilEtudiant.dart';
import 'profilEtud.dart';
import 'quizPage.dart';
import 'comptformateur.dart';
import 'DétailCoursEtudiant.dart';
import 'VideoCallPage.dart';
import 'video_call_service.dart';

class MesCoursEtudPage extends StatefulWidget {
  @override
  _MesCoursEtudPageState createState() => _MesCoursEtudPageState();
}

class _MesCoursEtudPageState extends State<MesCoursEtudPage> {
  String selectedCategory = 'Tous';
  String searchText = '';
  int _selectedIndex = 1;
  List<QueryDocumentSnapshot> categoriesList = [];
  final VideoCallService _videoCallService = VideoCallService();

  final Color backgroundColor = Color(0xFF9FB0CC);

  @override
  void initState() {
    super.initState();
    _loadInitialCategory();
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
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AccueilEtudiantPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilePage()));
    }
  }

  Widget _buildStarRating(QueryDocumentSnapshot courseDoc) {
    final data = courseDoc.data() as Map<String, dynamic>;
    double currentRating = (data['ratingEtudiant'] ?? 0).toDouble();

    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          iconSize: 28,
          onPressed: () async {
            // Update the 'ratingEtudiant' field directly in the purchase document
            await courseDoc.reference.update({'ratingEtudiant': index + 1});
            setState(() {}); // Refresh UI
          },
        );
      }),
    );
  }

  Future<bool> _isCallActive(String courseId) async {
    String channelName = 'skillbridge_course_${courseId.replaceAll(' ', '_')}';
    return await _videoCallService.isCallActive(channelName);
  }

  Future<void> _joinVideoCall(String courseId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Vérification de l'appel..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      String channelName = 'skillbridge_course_${courseId.replaceAll(' ', '_')}';
      bool isActive = await _videoCallService.isCallActive(channelName);
      
      Navigator.of(context).pop();
      
      if (isActive) {
        await _videoCallService.joinVideoCall(channelName);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallPage(
              channelName: channelName,
              isTrainer: false,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Aucun appel vidéo actif pour ce cours actuellement."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la connexion à l'appel: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un cours...',
                    hintStyle: const TextStyle(fontFamily: 'Comic Sans MS', color: Colors.black54),
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
                          backgroundColor: selectedCategory == 'Tous' ? Colors.grey : Colors.white38,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                        if (snapshot.hasError) return const Center(child: Text('Erreur de chargement'));
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final categories = snapshot.data!.docs;
                        return Row(
                          children: categories.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            // Ensure categoryName is always a String
                            final categoryName = (data['nom'] as String?) ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedCategory = categoryName;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedCategory == categoryName ? Colors.grey : Colors.white38,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                  stream: FirebaseFirestore.instance
                      .collection('purchases')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .where('isPaid', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Erreur de chargement'));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('Aucun cours acheté.'));
                    }

                    final filteredCourses = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      // Ensure title and category are always Strings for filtering
                      final title = ((data['title'] as String?) ?? '').toLowerCase();
                      final category = (data['category'] as String?) ?? '';
                      return (selectedCategory == 'Tous' || category == selectedCategory) &&
                          title.contains(searchText.toLowerCase());
                    }).toList();

                    if (filteredCourses.isEmpty) {
                      return Center(child: Text('Aucun cours trouvé.'));
                    }

                    return ListView.builder(
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final courseDoc = filteredCourses[index];
                        final data = courseDoc.data() as Map<String, dynamic>;

                        // Explicitly cast to String? and provide a default empty string
                        final title = (data['title'] as String?) ?? '';
                        final instructorName = (data['instructorName'] as String?) ?? 'Formateur inconnu';
                        final instructorId = (data['instructorId'] as String?) ?? '';
                        final courseId = (data['courseId'] as String?) ?? ''; // This is likely the purchase document ID, but if it's the original course ID from the 'courses' collection, ensure it's correct.
                        final courseIdOriginal = (data['courseIdOriginal'] as String?) ?? ''; // Use this for DetailCoursEtudiant and QuizPage if it links to the actual course

                        return GestureDetector(
                          onTap: () {
                            // Use courseIdOriginal if it represents the actual course document ID
                            if (courseIdOriginal.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailCoursEtudiant(courseId: courseIdOriginal),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("ID du cours original manquant pour les détails.")),
                              );
                            }
                          },
                          child: Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ), ElevatedButton.icon(
                                        onPressed: () {
                                          if (courseIdOriginal.isNotEmpty) {
                                            _joinVideoCall(courseIdOriginal);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("ID du cours original manquant pour l'appel vidéo.")),
                                            );
                                          }
                                        },
                                        icon: Icon(Icons.video_call),
                                        label: Text('Rejoindre l\'appel'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8), // Espace entre les boutons
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueGrey,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(0),
                                          ),
                                          minimumSize: Size(100, 36),
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        onPressed: () {
                                          if (courseIdOriginal.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => QuizPage(
                                                  courseId: courseIdOriginal,
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text("ID du cours original manquant pour le quiz.")),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          "Passer au quiz",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      if (instructorId.isNotEmpty) {
                                        final doc = await FirebaseFirestore.instance.collection('formateurs').doc(instructorId).get();
                                        if (doc.exists) {
                                          final formateurData = doc.data()!;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CompteForm(formateurId: instructorId, formData: formateurData),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text("Formateur introuvable")),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("ID du formateur manquant.")),
                                        );
                                      }
                                    },
                                    child: Text(
                                      instructorName,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Donnez votre avis :', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  _buildStarRating(courseDoc),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Mes cours'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
