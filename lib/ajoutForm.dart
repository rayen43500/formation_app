import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for TextInputFormatter
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjoutForm extends StatefulWidget {
  @override
  _AjoutFormState createState() => _AjoutFormState();
}

class _AjoutFormState extends State<AjoutForm> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF9FB0CC);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _dateController = TextEditingController();
  final _lieuController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeCoursController = TextEditingController();

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

  Widget buildTextField(String label,
      {bool obscure = false, TextEditingController? controller, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      inputFormatters: inputType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly] // Restrict to numbers only
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

  // Fonction pour valider le nom d'utilisateur
  String? _validateUsername(String username) {
    if (username.contains(" ")) {
      return "Le nom d'utilisateur ne doit pas contenir d'espaces.";
    } else if (username != username.toLowerCase()) {
      return "Le nom d'utilisateur ne doit pas contenir de majuscules.";
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String nom = _nomController.text.trim();
      String prenom = _prenomController.text.trim();
      String dateNaissance = _dateController.text.trim();
      String lieuNaissance = _lieuController.text.trim();
      String telephone = _telephoneController.text.trim();
      String email = _emailController.text.trim();
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();
      String codeCours = _codeCoursController.text.trim();

      // Validation du nom d'utilisateur
      String? usernameValidation = _validateUsername(username);
      if (usernameValidation != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(usernameValidation)),
        );
        return;
      }

      try {
        // Vérifier si le code de cours existe déjà
        final existingCodeCours = await _firestore
            .collection('formateurs')
            .where('code_cours', isEqualTo: codeCours)
            .get();
        if (existingCodeCours.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ce code cours est déjà utilisé.')),
          );
          return;
        }

        // Vérifier si le nom d'utilisateur existe déjà
        final existingUsername = await _firestore
            .collection('formateurs')
            .where('username', isEqualTo: username)
            .get();
        if (existingUsername.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ce nom d\'utilisateur est déjà utilisé.')),
          );
          return;
        }

        // 1. Créer l'utilisateur dans Firebase Auth
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 2. Ajouter les informations supplémentaires du formateur dans Firestore
        await _firestore.collection('formateurs').doc(userCredential.user!.uid).set({
          'nom': nom,
          'prenom': prenom,
          'date_naissance': dateNaissance,
          'lieu_naissance': lieuNaissance,
          'telephone': telephone,
          'email': email,
          'username': username,
          'code_cours': codeCours,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Formateur ajouté avec succès!')),
        );

        // Retour à la page précédente
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Une erreur s\'est produite lors de la création du compte.';
        if (e.code == 'weak-password') {
          errorMessage = 'Le mot de passe est trop faible.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        print('Erreur lors de l\'ajout du formateur: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur inattendue s\'est produite.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Couleur de fond de la page
      appBar: AppBar(
        title: Text('Ajouter un Formateur'),
        backgroundColor: primaryColor, // Couleur de fond de l'AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle("Nom et Prénom"),
              Row(
                children: [
                  Expanded(child: buildTextField("Nom", controller: _nomController)),
                  const SizedBox(width: 10),
                  Expanded(child: buildTextField("Prénom", controller: _prenomController)),
                ],
              ),

              sectionTitle("Date et lieu de naissance"),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: InputDecoration(
                        labelText: "JJ/MM/AAAA",
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: buildTextField("Lieu de naissance",
                          controller: _lieuController)),
                ],
              ),

              sectionTitle("Numéro de téléphone"),
              buildTextField("Numéro de téléphone",
                  controller: _telephoneController, inputType: TextInputType.phone),

              sectionTitle("Adresse E-mail"),
              buildTextField("Adresse E-mail", controller: _emailController),

              sectionTitle("Nom d'utilisateur"),
              buildTextField("Nom d'utilisateur", controller: _usernameController),

              sectionTitle("Code Cours"),
              buildTextField("Code Cours", controller: _codeCoursController),

              sectionTitle("Mot de passe"),
              buildTextField("Mot de passe",
                  obscure: true, controller: _passwordController),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey, // Vous pouvez choisir une autre couleur pour le bouton
                    padding:
                    EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Ajoute le formateur",
                      style: TextStyle(fontSize: 16,color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
