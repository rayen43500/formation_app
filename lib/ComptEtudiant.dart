import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ComptesEtudiantsPage extends StatelessWidget {
  final String userId;

  const ComptesEtudiantsPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9DAFCB),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('Utilisateur non trouvé'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            final String? photoUrl = data['photoProfil'];
            final String? nom = data['nom'];
            final String? prenom = data['prenom'];
            final String? email = data['email'];
            final String? consignes = data['consignes'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Titre et logo (comme dans ton code)
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Skill',
                                style: GoogleFonts.greatVibes(
                                    fontSize: 48,
                                    color: Color(0xFFB29245),
                                    fontWeight: FontWeight.bold)),
                            Text(' Bridge',
                                style: GoogleFonts.greatVibes(
                                    fontSize: 48,
                                    color: Color(0xFFB29245),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('E-Learning',
                            style: GoogleFonts.roboto(
                                fontSize: 18, color: Color(0xFF8D8B45))),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Photo profil
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[600],
                    )
                        : null,
                  ),
                  SizedBox(height: 20),

                  // Info container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoRow("Nom", nom),
                        infoRow("Prénom", prenom),
                        infoRow("Email", email),
                        SizedBox(height: 20),
                        Text(
                          "Consignes :",
                          style: TextStyle(
                            fontFamily: 'Comic Sans MS',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          consignes ?? 'Aucune consigne disponible',
                          style: TextStyle(
                            fontFamily: 'Comic Sans MS',
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: Colors.blueGrey),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Comic Sans MS',
                  fontSize: 15,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: "$label : ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: value ?? 'Non défini',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}