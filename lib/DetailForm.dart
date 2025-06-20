import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import 'EditFormPage.dart';

class DetailForm extends StatefulWidget {
  final String formateurId;
  final Map<String, dynamic> formData;

  DetailForm({required this.formateurId, required this.formData});

  @override
  State<DetailForm> createState() => _DetailFormState();
}

class _DetailFormState extends State<DetailForm> {
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    photoUrl = widget.formData['photoUrl'];
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      final cloudName = 'deltanzkn';       // <-- Remplace ici
      final uploadPreset = 'skillbridge'; // <-- Remplace ici

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'profile.jpg',
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        final downloadUrl = jsonData['secure_url'];

        await FirebaseFirestore.instance
            .collection('formateurs')
            .doc(widget.formateurId)
            .set({'photoUrl': downloadUrl}, SetOptions(merge: true));

        setState(() {
          photoUrl = downloadUrl;
        });
      } else {
        print('Erreur upload Cloudinary: ${response.statusCode}');
        // Tu peux ajouter un snackbar ou autre pour informer l'utilisateur
      }
    }
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

              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage:
                      (photoUrl != null && photoUrl!.isNotEmpty)
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: (photoUrl == null || photoUrl!.isEmpty)
                          ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      )
                          : null,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

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
                    infoRow("Nom", widget.formData['nom']),
                    infoRow("Prénom", widget.formData['prenom']),
                    infoRow("Date de naissance", widget.formData['date_naissance']),
                    infoRow("Lieu de naissance", widget.formData['lieu_naissance']),
                    infoRow("Téléphone", widget.formData['telephone']),
                    infoRow("Email", widget.formData['email']),
                    infoRow("Nom d'utilisateur", widget.formData['username']),
                    infoRow("Code cours", widget.formData['code_cours']),
                  ],
                ),
              ),

              SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditFormPage(
                        formateurId: widget.formateurId,
                        formData: widget.formData,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: Icon(Icons.edit, color: Colors.white),
                label: Text(
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
            child: Text(
              "$label : ${value ?? 'Non défini'}",
              style: TextStyle(
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
}
