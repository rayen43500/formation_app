import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CompteForm extends StatelessWidget {
  final String formateurId;
  final Map<String, dynamic> formData;

  CompteForm({required this.formateurId, required this.formData});

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = formData['photoUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFF9DAFCB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
              SizedBox(height: 20),

              // Avatar ou photo de profil
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

              // Info Container
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
                    // On garde ces lignes
                    infoRow("Nom", formData['nom']),
                    infoRow("Prénom", formData['prenom']),
                    infoRow("Email", formData['email']),

                    SizedBox(height: 20),

                    // Puis on affiche la liste des cours du formateur
                    Text(
                      "Cours ajoutés:",
                      style: TextStyle(
                        fontFamily: 'Comic Sans MS',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('courses')
                          .where('instructorId', isEqualTo: formateurId)
                          .where('status', isEqualTo: "Validé")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Text(
                            "Aucun cours trouvé.",
                            style: TextStyle(fontFamily: 'Comic Sans MS'),
                          );
                        }

                        final coursDocs = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: coursDocs.length,
                          itemBuilder: (context, index) {
                            final cours =
                            coursDocs[index].data()! as Map<String, dynamic>;
                            final titre = cours['title'] ?? 'Titre non défini';
                            final description = cours['description'] ?? '';

                            return ListTile(
                              leading: Icon(Icons.book, color: Colors.blueGrey),
                              title: Text(
                                titre,
                                style: TextStyle(
                                  fontFamily: 'Comic Sans MS',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                description,
                                style: TextStyle(fontFamily: 'Comic Sans MS'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
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
