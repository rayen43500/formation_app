import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    photoUrl = widget.formData['photoUrl'];
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

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();

        final cloudName = 'deltanzkn';
        final uploadPreset = 'skillbridge';

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
          
          _showSuccessSnackBar("Photo de profil mise à jour avec succès");
        } else {
          _showErrorSnackBar('Erreur lors du téléchargement de l\'image');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          'Détails du profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // En-tête avec logo
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Skill',
                          style: GoogleFonts.greatVibes(
                            fontSize: 42,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' Bridge',
                          style: GoogleFonts.greatVibes(
                            fontSize: 42,
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Profil Enseignant',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey[700],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Photo de profil
              _isLoading 
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  )
                : GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
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
                          image: (photoUrl != null && photoUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (photoUrl == null || photoUrl!.isEmpty)
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              )
                            : null,
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 30),

              // Informations personnelles
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Informations personnelles",
                      style: AppTheme.headingMedium,
                    ),
                    Divider(height: 20, color: AppTheme.primaryColor.withOpacity(0.2)),
                    infoRow(Icons.person, "Nom", widget.formData['nom']),
                    infoRow(Icons.person_outline, "Prénom", widget.formData['prenom']),
                    infoRow(Icons.calendar_today, "Date de naissance", widget.formData['date_naissance']),
                    infoRow(Icons.location_on_outlined, "Lieu de naissance", widget.formData['lieu_naissance']),
                  ],
                ),
              ),

              SizedBox(height: 20),
              
              // Informations de contact
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Coordonnées",
                      style: AppTheme.headingMedium,
                    ),
                    Divider(height: 20, color: AppTheme.primaryColor.withOpacity(0.2)),
                    infoRow(Icons.phone, "Téléphone", widget.formData['telephone']),
                    infoRow(Icons.email_outlined, "Email", widget.formData['email']),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Informations de compte
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  boxShadow: [AppTheme.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Informations de compte",
                      style: AppTheme.headingMedium,
                    ),
                    Divider(height: 20, color: AppTheme.primaryColor.withOpacity(0.2)),
                    infoRow(Icons.person_pin, "Nom d'utilisateur", widget.formData['username']),
                    infoRow(Icons.vpn_key_outlined, "Code cours", widget.formData['code_cours']),
                  ],
                ),
              ),

              SizedBox(height: 30),

              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
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
                  style: AppTheme.primaryButtonStyle,
                  icon: Icon(Icons.edit, color: Colors.white),
                  label: Text(
                    "Modifier le profil",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value ?? 'Non défini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
