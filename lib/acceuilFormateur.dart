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
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AccueilFormateur extends StatefulWidget {
  @override
  _AccueilFormateurState createState() => _AccueilFormateurState();
}

class _AccueilFormateurState extends State<AccueilFormateur> with SingleTickerProviderStateMixin {
  String selectedPage = 'Accueil';
  String selectedCategory = 'Tous';
  TabController? _tabController;
  bool _isLoading = false;

  final CollectionReference _categoriesCollection =
      FirebaseFirestore.instance.collection('categories');
  final CollectionReference _coursCollection =
      FirebaseFirestore.instance.collection('courses');
  final String formateurId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String searchText = '';
  
  // Service d'appel vidéo
  final VideoCallService _videoCallService = VideoCallService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Afficher le dialogue de confirmation pour démarrer un appel
  Future<void> _showStartCallDialog(BuildContext context, DocumentSnapshot cours) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Démarrer un appel vidéo',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous allez démarrer un appel vidéo pour le cours:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cours['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Les étudiants inscrits à ce cours pourront rejoindre la session.',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
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
                backgroundColor: AppTheme.secondaryColor,
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: selectedPage == 'Accueil' 
        ? AppBar(
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            title: Text(
              'Tableau de bord Enseignant',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: [
                Tab(text: 'Mes cours'),
                Tab(text: 'Statistiques'),
              ],
            ),
          )
        : null,
      body: SafeArea(
        child: selectedPage == 'Accueil'
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec recherche
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barre de recherche
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchText = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Rechercher un cours...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Catégories
                      Text(
                        'Filtrer par catégorie:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      
                      Container(
                        height: 40,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _categoriesCollection.snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              );
                            }

                            List<DocumentSnapshot> docs = snapshot.data!.docs;

                            return ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    selected: selectedCategory == 'Tous',
                                    onSelected: (selected) {
                                      setState(() {
                                        selectedCategory = 'Tous';
                                      });
                                    },
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    selectedColor: Colors.white,
                                    checkmarkColor: AppTheme.primaryColor,
                                    labelStyle: TextStyle(
                                      color: selectedCategory == 'Tous'
                                          ? AppTheme.primaryColor
                                          : Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    label: Text('Tous'),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                ...docs.map((doc) {
                                  String categoryName = doc['nom'];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      selected: selectedCategory == categoryName,
                                      onSelected: (selected) {
                                        setState(() {
                                          selectedCategory = categoryName;
                                        });
                                      },
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      selectedColor: Colors.white,
                                      checkmarkColor: AppTheme.primaryColor,
                                      labelStyle: TextStyle(
                                        color: selectedCategory == categoryName
                                            ? AppTheme.primaryColor
                                            : Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      label: Text(categoryName),
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenu principal
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCoursValidesAccueil(),
                      Center(child: Text('Statistiques à venir')),
                    ],
                  ),
                ),
              ],
            )
          : ProfileformPage(),
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
          currentIndex: selectedPage == 'Accueil' ? 0 : 1,
          onTap: (index) {
            setState(() {
              selectedPage = index == 0 ? 'Accueil' : 'Profil';
            });
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
      floatingActionButton: selectedPage == 'Accueil'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AjoutCoursPage()),
                );
              },
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              icon: Icon(Icons.add),
              label: Text('Nouveau cours'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMesCours() {
    return StreamBuilder<QuerySnapshot>(
      stream: _coursCollection
          .where('instructorId', isEqualTo: formateurId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );

        final coursDocs = snapshot.data!.docs;

        if (coursDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun cours trouvé',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Commencez par créer un nouveau cours',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
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
          .where('instructorId', isEqualTo: formateurId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );

        List<QueryDocumentSnapshot> coursDocs = snapshot.data!.docs;

        // Filtrer par catégorie si nécessaire
        if (selectedCategory != 'Tous') {
          coursDocs = coursDocs
              .where((doc) => doc['category'] == selectedCategory)
              .toList();
        }
        
        // Filtrer par recherche si nécessaire
        if (searchText.isNotEmpty) {
          coursDocs = coursDocs
              .where((doc) => 
                  doc['title'].toString().toLowerCase().contains(searchText) ||
                  doc['description'].toString().toLowerCase().contains(searchText))
              .toList();
        }

        if (coursDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Aucun cours trouvé',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Essayez de modifier vos critères de recherche',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: coursDocs.length,
          itemBuilder: (context, index) {
            return buildCourseCard(coursDocs[index]);
          },
        );
      },
    );
  }

  Widget buildCourseCard(DocumentSnapshot cours) {
    String status = cours['status'] ?? 'En attente';
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'Validé':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Refusé':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        children: [
          // En-tête de la carte
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                topRight: Radius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.school,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cours['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                statusIcon,
                                color: statusColor,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(
                                Icons.category,
                                color: AppTheme.textSecondaryColor,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                cours['category'] ?? 'Non catégorisé',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.video_call,
                        color: AppTheme.secondaryColor,
                        size: 30,
                      ),
                      onPressed: () {
                        _showStartCallDialog(context, cours);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  cours['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          
          // Actions
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.edit,
                    label: 'Modifier',
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModificationCoursPage(cours: cours),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.quiz,
                    label: 'Ajouter quiz',
                    color: Colors.purple,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AjoutQuizPage(coursId: cours.id),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.bar_chart,
                    label: 'Statistiques',
                    color: Colors.blue,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StatiCoursAdminPage(courseId: cours.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton de suppression
          Padding(
            padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: InkWell(
              onTap: () async {
                bool confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Confirmation"),
                    content: Text("Êtes-vous sûr de vouloir supprimer ce cours ?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Annuler"),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Supprimer"),
                      ),
                    ],
                  ),
                );

                if (confirm) {
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    await _coursCollection.doc(cours.id).delete();
                    _showSuccessSnackBar("Cours supprimé avec succès");
                  } catch (e) {
                    _showErrorSnackBar("Erreur lors de la suppression");
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Supprimer le cours',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        elevation: 0,
      ),
    );
  }
}
