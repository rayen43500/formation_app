import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DetailForm.dart';
import 'GestionCertif.dart';
import 'acceuilFormateur.dart';
import 'theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileformPage extends StatefulWidget {
  @override
  _ProfileformPageState createState() => _ProfileformPageState();
}

class _ProfileformPageState extends State<ProfileformPage> {
  bool _isLoading = false;

  // Récupère les données du formateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('formateurs').doc(uid).get();
    return doc.data();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Formateur non trouvé",
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
            );
          }

          final userData = snapshot.data!;
          final fullName = "${userData['prenom']} ${userData['nom']}";
          final photoUrl = userData['photoUrl'];
          final email = userData['email'];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Header avec photo de profil
                Container(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          image: photoUrl != null && photoUrl.toString().isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoUrl == null || photoUrl.toString().isEmpty
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                      SizedBox(height: 15),
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 5),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Enseignant",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Statistiques
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    boxShadow: [AppTheme.cardShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Statistiques",
                        style: AppTheme.headingMedium,
                      ),
                      Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            icon: Icons.book,
                            value: "12",
                            label: "Cours",
                            color: AppTheme.primaryColor,
                          ),
                          _buildStatItem(
                            icon: Icons.people,
                            value: "156",
                            label: "Étudiants",
                            color: AppTheme.secondaryColor,
                          ),
                          _buildStatItem(
                            icon: Icons.star,
                            value: "4.8",
                            label: "Note",
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Options de profil
                _buildMenuCard(
                  title: "Gestion du profil",
                  description: "Modifier vos informations personnelles",
                  icon: Icons.person_outline,
                  onTap: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      final userData = await getUserData();
                      if (userData != null) {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailForm(
                                formateurId: userId,
                                formData: userData,
                              ),
                            ),
                          );
                        }
                      }
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                ),

                SizedBox(height: 15),

                _buildMenuCard(
                  title: "Gestion des quizzes",
                  description: "Créer et gérer vos quizzes et certifications",
                  icon: Icons.quiz_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GestionCertificationPage()),
                    );
                  },
                ),

                SizedBox(height: 15),

                _buildMenuCard(
                  title: "Statistiques des cours",
                  description: "Consultez les performances de vos cours",
                  icon: Icons.bar_chart,
                  onTap: () {
                    // Navigation vers les statistiques
                  },
                ),

                SizedBox(height: 15),

                _buildMenuCard(
                  title: "Planification des sessions",
                  description: "Gérer les sessions de cours en direct",
                  icon: Icons.calendar_today,
                  onTap: () {
                    // Navigation vers la planification
                  },
                ),

                SizedBox(height: 30),

                // Bouton de déconnexion
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Confirmation"),
                          content: Text("Voulez-vous vraiment vous déconnecter ?"),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                          ),
                          actions: [
                            TextButton(
                              child: Text("Annuler"),
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text("Se déconnecter"),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        setState(() {
                          _isLoading = true;
                        });
                        
                        try {
                          await FirebaseAuth.instance.signOut();
                          _showSuccessSnackBar("Déconnecté avec succès");
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    icon: Icon(Icons.logout, color: Colors.white),
                    label: _isLoading 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Déconnexion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
                
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
