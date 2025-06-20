import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ly_na/EditEtud.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilEtud extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ProfilEtud({super.key, required this.userId, required this.userData});

  String formatDate(dynamic date) {
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      return formatter.format(dateTime);
    } else if (date is String) {
      try {
        final DateTime dateTime = DateFormat('yyyy-MM-dd').parse(date);
        final DateFormat formatter = DateFormat('dd/MM/yyyy');
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$label : ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Comic Sans MS',
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: displayValue,
                    style: const TextStyle(
                      fontFamily: 'Comic Sans MS',
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<ProfilEtud> createState() => _ProfilEtudState();
}

class _ProfilEtudState extends State<ProfilEtud> {
  bool _isUploading = false;

  final String cloudinaryUploadPreset = 'skillbridge';
  final String cloudinaryCloudName = 'deltanzkn';

  Future<void> _uploadNewPhoto() async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.image,
      fileExtensionsFilter: ['jpg', 'jpeg', 'png'],
    );

    final filePath = await FlutterFileDialog.pickFile(params: params);
    if (filePath == null) return;

    final File file = File(filePath);

    setState(() {
      _isUploading = true;
    });

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        final downloadURL = jsonResponse['secure_url'];

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update({'photoUrl': downloadURL});

        setState(() {
          widget.userData['photoUrl'] = downloadURL;
        });
      } else {
        print('Erreur Cloudinary: ${response.reasonPhrase}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du téléchargement de la photo')),
        );
      }
    } catch (e) {
      print("Erreur : $e");
    }

    setState(() {
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.userData['photoUrl'];

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

              // Avatar avec possibilité d'édition
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _uploadNewPhoto,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: (photoUrl != null && photoUrl != '')
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl == '')
                          ? const Icon(Icons.person,
                          size: 60, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadNewPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Informations utilisateur
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
                    widget.infoRow("Nom d'utilisateur", widget.userData['username']),
                    widget.infoRow("Nom", widget.userData['nom']),
                    widget.infoRow("Prénom", widget.userData['prenom']),
                    widget.infoRow("Date de naissance", widget.formatDate(widget.userData['date_naissance'])),
                    widget.infoRow("Niveau d'études", widget.userData['niveau']),
                    widget.infoRow("Compétences", widget.userData['competences']),
                    widget.infoRow("Email", widget.userData['email']),
                    widget.infoRow("Téléphone", widget.userData['telephone']),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditEtud(
                              userId: widget.userId,
                              userData: widget.userData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        "Modifier",
                        style: TextStyle(
                          fontFamily: 'Comic Sans MS',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
