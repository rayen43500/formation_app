import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gestprofilEtud.dart'; // Assurez-vous que ce fichier est correctement importé
import 'ListeQuizValidesPage.dart';

class ProfilePage extends StatelessWidget {
  final Color backgroundColor = Color(0xFF9FB0CC);

  // Récupère les données de l'utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Arrière-plan de la page
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: backgroundColor,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(  // Récupérer les données utilisateur
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("Utilisateur non trouvé", style: TextStyle(color: Colors.black)));
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Pour plus de contraste
                  ),
                ),
                SizedBox(height: 20),
                // Section "Gestion du profil"
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
                                builder: (context) => ProfilEtud(
                                  userId: userId, // Passer l'ID de l'utilisateur connecté
                                  userData: userData, // Passer les données utilisateur
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
                // Section "Liste des quizs validés"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white54,
                    ),
                    child: ListTile(
                      title: Text('Liste des quizs validés'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QuizValidePage()),
                        );
                      },
                    ),

                  ),
                ),
                // Section "Déconnexion"
                // Section "Déconnexion"
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

                          // Retour à la page de login
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
