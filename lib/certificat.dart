import 'package:flutter/material.dart';

class CertificatPage extends StatelessWidget {
  final String studentName;
  final String courseTitle;
  final String quizTitle;
  final String mention;
  final String date;

  const CertificatPage({
    super.key,
    required this.studentName,
    required this.courseTitle,
    required this.quizTitle,
    required this.mention,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.black87, width: 2),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Certificat',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DeParticipation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ce certificat est remis à',
                  style: TextStyle(letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontFamily: 'Cursive',
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pour avoir complété avec succès le cours :\n"$courseTitle"\n'
                      'et avoir passé le quiz "$quizTitle" avec la mention : $mention',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Skill Bridge',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'Cursive',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8860B), // golden
                      ),
                    ),
                    Text(
                      'Date de délivrance : $date',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
