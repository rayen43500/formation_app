// detailEtud.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailEtud extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const DetailEtud({super.key, required this.userId, required this.userData});

  String formatDate(dynamic date) {
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(dateTime);
    } else if (date is String) {
      try {
        final DateTime dateTime = DateFormat('yyyy-MM-dd').parse(date);
        final DateFormat formatter = DateFormat('dd/MM/yyyy'); // Suppression de HH:mm ici
        return formatter.format(dateTime);
      } catch (e) {
        return date;
      }
    }
    return 'Non défini';
  }

  Widget infoRow(String label, dynamic value) {
    String displayValue;
    if (value is List) {
      displayValue = value.join(', ');
    } else {
      displayValue = value?.toString() ?? 'Non défini';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label : $displayValue",
              style: const TextStyle(
                fontFamily: 'Comic Sans MS',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                color: const Color(0xFFB29245),
                                fontWeight: FontWeight.bold)),
                        Text(' Bridge',
                            style: GoogleFonts.greatVibes(
                                fontSize: 48,
                                color: const Color(0xFFB29245),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('E-Learning',
                        style: GoogleFonts.roboto(
                            fontSize: 18, color: const Color(0xFF8D8B45))),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Avatar ou photo de profil
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: userData['photoUrl'] != null && userData['photoUrl'] != ''
                    ? NetworkImage(userData['photoUrl'])
                    : null,
                child: userData['photoUrl'] == null || userData['photoUrl'] == ''
                    ? const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                )
                    : null,
              ),

              const SizedBox(height: 20),

              // Conteneur des informations
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
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
                    infoRow("Nom d'utilisateur", userData['username']),
                    infoRow("Nom", userData['nom']),
                    infoRow("Prénom", userData['prenom']),
                    infoRow("Date de naissance", formatDate(userData['date_naissance'])),
                    infoRow("Niveau d'études", userData['niveau']),
                    infoRow("Compétences", userData['competences']),
                    infoRow("Email", userData['email']),
                    infoRow("Téléphone", userData['telephone']),
                    infoRow("Date d'inscription", formatDate(userData['createdAt'])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}