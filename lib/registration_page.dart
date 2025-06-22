import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'acceuilEtudiant.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  File? _image;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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

    if (username.isEmpty) return;

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
      _showErrorSnackBar('Erreur lors de la sélection de l\'image');
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
        _showErrorSnackBar('Veuillez saisir un email valide');
        return;
      }

      if (!_isUsernameValid) {
        _showErrorSnackBar('Nom d\'utilisateur invalide ou déjà pris');
        return;
      }

      if (_passwordController.text.length < 8) {
        _showErrorSnackBar('Le mot de passe doit contenir au moins 8 caractères');
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorSnackBar('Les mots de passe ne correspondent pas');
        return;
      }

      setState(() {
        _isLoading = true;
      });

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
            _showErrorSnackBar('Erreur lors de l\'upload de la photo');
            setState(() {
              _isLoading = false;
            });
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

        _showSuccessSnackBar('Inscription réussie !');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccueilEtudiantPage()),
        );
      } catch (e) {
        _showErrorSnackBar('Erreur : ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // Create user profile in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'nom': googleUser.displayName?.split(' ').last ?? '',
          'prenom': googleUser.displayName?.split(' ').first ?? '',
          'email': googleUser.email,
          'username': googleUser.email.split('@').first,
          'photoUrl': googleUser.photoUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'niveau': 'Non spécifié',
          'competences': ['Non spécifié'],
        });
        
        _showSuccessSnackBar('Compte créé avec Google avec succès !');
      } else {
        _showSuccessSnackBar('Connexion avec Google réussie !');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccueilEtudiantPage()),
      );
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'inscription avec Google: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildTextField(String label,
      {bool obscure = false,
        TextEditingController? controller,
        TextInputType inputType = TextInputType.text,
        IconData? prefixIcon}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
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
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primaryColor) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Divider(color: AppTheme.primaryColor.withOpacity(0.3), thickness: 1),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: Text(
          'Inscription',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                            'E-Learning Platform',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.grey[700],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Option d'inscription rapide avec Google
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Inscription rapide",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: _registerWithGoogle,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/google-pay-mark.png',
                                          height: 24,
                                          width: 50,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'S\'inscrire avec Google',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Séparateur
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[400])),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'OU INSCRIPTION MANUELLE',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[400])),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                                image: _image != null
                                    ? DecorationImage(
                                        image: FileImage(_image!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _image == null
                                  ? Center(
                                      child: Icon(
                                        Icons.add_a_photo,
                                        color: AppTheme.primaryColor,
                                        size: 40,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Photo de profil',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    sectionTitle('Informations personnelles'),

                    buildTextField('Nom', controller: _nomController, prefixIcon: Icons.person),
                    const SizedBox(height: 15),
                    buildTextField('Prénom', controller: _prenomController, prefixIcon: Icons.person_outline),
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date de naissance',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                          ),
                        ),
                        onTap: () => _selectDate(context),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ce champ est requis' : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    buildTextField('Lieu de naissance', controller: _lieuController, prefixIcon: Icons.location_on_outlined),
                    const SizedBox(height: 15),
                    buildTextField('Téléphone',
                        controller: _telephoneController,
                        inputType: TextInputType.phone,
                        prefixIcon: Icons.phone),
                    const SizedBox(height: 15),

                    sectionTitle('Niveau d\'étude'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.school, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        value: _selectedNiveau,
                        hint: Text('Sélectionnez votre niveau'),
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
                    ),
                    const SizedBox(height: 15),

                    sectionTitle('Compétences'),
                    ..._skillsControllers
                        .asMap()
                        .entries
                        .map(
                          (entry) => Container(
                            margin: EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: entry.value,
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? 'Ce champ est requis'
                                              : null,
                                      decoration: InputDecoration(
                                        labelText: 'Compétence ${entry.key + 1}',
                                        labelStyle: TextStyle(color: Colors.grey[700]),
                                        prefixIcon: Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.remove_circle, color: Colors.red[400]),
                                    onPressed: () {
                                      if (_skillsControllers.length > 1) {
                                        setState(() {
                                          _skillsControllers.removeAt(entry.key);
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: Icon(Icons.add_circle, color: AppTheme.secondaryColor),
                        label: Text(
                          'Ajouter compétence',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _skillsControllers.add(TextEditingController());
                          });
                        },
                      ),
                    ),

                    sectionTitle('Compte utilisateur'),

                    buildTextField(
                      'Email',
                      controller: _emailController,
                      inputType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 15),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Nom d\'utilisateur',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: Icon(Icons.person_pin, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide(color: Colors.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                            borderSide: BorderSide(color: Colors.red, width: 1),
                          ),
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
                    ),
                    const SizedBox(height: 15),

                    buildTextField(
                      'Mot de passe',
                      controller: _passwordController,
                      obscure: true,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 15),

                    buildTextField(
                      'Confirmer le mot de passe',
                      controller: _confirmPasswordController,
                      obscure: true,
                      prefixIcon: Icons.lock,
                    ),
                    const SizedBox(height: 30),

                    Center(
                      child: Container(
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
                        child: ElevatedButton(
                          onPressed: registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'S\'inscrire',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
