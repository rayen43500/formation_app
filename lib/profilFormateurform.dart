import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DetailForm.dart'; // Import de la nouvelle page
import 'GestionCertif.dart';
import 'acceuilFormateur.dart';

class ProfileformPage extends StatelessWidget {
  final Color backgroundColor = Color(0xFF9FB0CC);

  // Récupère les données du formateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('formateurs').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Profil Formateur'),
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AccueilFormateur()),
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("Formateur non trouvé", style: TextStyle(color: Colors.black)));
          }

          final userData = snapshot.data!;
          final fullName = "${userData['prenom']} ${userData['nom']}";

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty
                        ? NetworkImage(userData['photoUrl'])
                        : null,
                    child: userData['photoUrl'] == null || userData['photoUrl'].toString().isEmpty
                        ? Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey[600],
                    )
                        : null,
                  ),
                ),
                Text(
                  fullName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 20),

                // Bouton gestion du profil
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white54,
                    ),
                    child: ListTile(
                      title: Text('Gestion du profil'),
                      onTap: () async {
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
                      },
                    ),
                  ),
                ),

                // Autres sections (certifications, quizs validés...)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white54,
                    ),
                    child: ListTile(
                      title: Text('Gestion des quizzes'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GestionCertificationPage()),
                        );
                      },
                    ),
                  ),
                ),
                // Bouton de déconnexion
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white54,
                    ),
                    child: ListTile(
                      title: Text('Déconnexion'),
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text("Voulez-vous vraiment vous déconnecter ?"),
                            actions: [
                              TextButton(
                                child: const Text("Annuler"),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text("Se déconnecter"),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Déconnecté avec succès")),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
