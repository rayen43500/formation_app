import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart'; // pour flutter_file_dialog
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'acceuilEtudiant.dart';
import 'package:flutter/services.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final Color backgroundColor = Color(0xFFB0C4DE);
  final Color buttonColor = Color(0xFF5865F2);
  final TextStyle subtitleStyle = TextStyle(
    fontFamily: 'Times New Roman',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  File? _image;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _lieuController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dateController = TextEditingController();
  List<TextEditingController> _skillsControllers = [TextEditingController()];

  String? _selectedNiveau;

  // Username validation
  bool _isUsernameValid = false;
  String _usernameErrorText = '';

  // Remplace par tes infos Cloudinary
  final String cloudinaryUploadPreset = 'skillbridge';
  final String cloudinaryCloudName = 'deltanzkn';

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateUsername);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_validateUsername);
    _usernameController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _lieuController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    for (var ctrl in _skillsControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _validateUsername() async {
    String username = _usernameController.text.trim();

    if (username.contains(' ') || username != username.toLowerCase()) {
      setState(() {
        _isUsernameValid = false;
        _usernameErrorText = 'Doit être en minuscules et sans espaces';
      });
      return;
    }

    final usernameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    setState(() {
      _isUsernameValid = usernameQuery.docs.isEmpty;
      _usernameErrorText =
      _isUsernameValid ? '' : 'Nom d\'utilisateur déjà pris';
    });
  }

  bool isValidEmail(String email) {
    final RegExp regex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    return regex.hasMatch(email);
  }

  // Utilisation de flutter_file_dialog pour choisir une image
  Future<void> _pickImage() async {
    try {
      final params = OpenFileDialogParams(
        dialogType: OpenFileDialogType.image,
      );
      final filePath = await FlutterFileDialog.pickFile(params: params);
      if (filePath != null) {
        setState(() {
          _image = File(filePath);
        });
      }
    } catch (e) {
      print('Erreur sélection image: $e');
    }
  }

  // Fonction upload sur Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final uri = Uri.parse(
          "https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload");

      var request = http.MultipartRequest('POST', uri);

      // Ajouter preset (upload preset Cloudinary)
      request.fields['upload_preset'] = cloudinaryUploadPreset;

      // Ajouter fichier image
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['secure_url']; // URL de l'image hébergée
      } else {
        print('Erreur Cloudinary: ${response.statusCode}');
        print(response.body);
        return null;
      }
    } catch (e) {
      print('Exception upload Cloudinary: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.day.toString().padLeft(2, '0')}/"
            "${pickedDate.month.toString().padLeft(2, '0')}/"
            "${pickedDate.year}";
      });
    }
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (!isValidEmail(_emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez saisir un email valide')),
        );
        return;
      }

      if (!_isUsernameValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nom d\'utilisateur invalide ou déjà pris')),
        );
        return;
      }

      if (_passwordController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Le mot de passe doit contenir au moins 8 caractères')),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Les mots de passe ne correspondent pas')),
        );
        return;
      }

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String? photoUrl;
        if (_image != null) {
          photoUrl = await _uploadToCloudinary(_image!);
          if (photoUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur lors de l\'upload de la photo')),
            );
            return;
          }
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'nom': _nomController.text,
          'prenom': _prenomController.text,
          'date_naissance': _dateController.text,
          'lieu_naissance': _lieuController.text,
          'telephone': _telephoneController.text,
          'email': _emailController.text,
          'niveau': _selectedNiveau,
          'competences': _skillsControllers.map((e) => e.text).toList(),
          'username': _usernameController.text.trim(),
          'photoUrl': photoUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccueilEtudiantPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  Widget buildTextField(String label,
      {bool obscure = false,
        TextEditingController? controller,
        TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      inputFormatters: inputType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text('E-Learning', style: GoogleFonts.roboto(fontSize: 18, color: Color(0xFF8D8B45))),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(50),
                          image: _image != null
                              ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: _image == null
                            ? Center(
                          child: Icon(Icons.add_a_photo,
                              color: Colors.grey[700], size: 40),
                        )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              sectionTitle('Informations personnelles'),

              buildTextField('Nom', controller: _nomController),
              const SizedBox(height: 15),
              buildTextField('Prénom', controller: _prenomController),
              const SizedBox(height: 15),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
                validator: (value) =>
                value == null || value.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 15),
              buildTextField('Lieu de naissance', controller: _lieuController),
              const SizedBox(height: 15),
              buildTextField('Téléphone',
                  controller: _telephoneController,
                  inputType: TextInputType.phone),
              const SizedBox(height: 15),

              sectionTitle('Niveau d\'étude'),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
                value: _selectedNiveau,
                items: [
                  "Bac",
                  "Licence",
                  "Master",
                  "Ingénierie",
                  "Doctorat"
                ].map((niveau) {
                  return DropdownMenuItem<String>(
                    value: niveau,
                    child: Text(niveau),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedNiveau = val;
                  });
                },
                validator: (value) =>
                value == null ? 'Veuillez sélectionner un niveau' : null,
              ),
              const SizedBox(height: 15),

              sectionTitle('Compétences'),
              ..._skillsControllers
                  .asMap()
                  .entries
                  .map(
                    (entry) => Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry.value,
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Ce champ est requis'
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Compétence ${entry.key + 1}',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.grey),
                      onPressed: () {
                        if (_skillsControllers.length > 1) {
                          setState(() {
                            _skillsControllers.removeAt(entry.key);
                          });
                        }
                      },
                    ),
                  ],
                ),
              )
                  .toList(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Ajouter compétence'),
                  onPressed: () {
                    setState(() {
                      _skillsControllers.add(TextEditingController());
                    });
                  },
                ),
              ),

              sectionTitle('Compte utilisateur'),

              buildTextField('Email',
                  controller: _emailController,
                  inputType: TextInputType.emailAddress),
              const SizedBox(height: 15),

              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  border: OutlineInputBorder(),
                  errorText:
                  _isUsernameValid ? null : (_usernameErrorText.isNotEmpty ? _usernameErrorText : null),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est requis';
                  }
                  if (!_isUsernameValid) {
                    return _usernameErrorText;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              buildTextField('Mot de passe',
                  controller: _passwordController, obscure: true),
              const SizedBox(height: 15),

              buildTextField('Confirmer le mot de passe',
                  controller: _confirmPasswordController, obscure: true),
              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding:
                    EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('S\'inscrire',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
