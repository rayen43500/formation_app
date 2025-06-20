import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gestprofilEtud.dart'; // Make sure this import is correct

class EditEtud extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditEtud({Key? key, required this.userId, required this.userData}) : super(key: key);

  @override
  _EditEtudState createState() => _EditEtudState();
}

class _EditEtudState extends State<EditEtud> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController emailController;
  late TextEditingController telController;
  late TextEditingController usernameController;
  late TextEditingController competController;
  late TextEditingController etudeController;
  late TextEditingController dateController;
  late TextEditingController lieuController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.userData['nom']);
    prenomController = TextEditingController(text: widget.userData['prenom']);
    emailController = TextEditingController(text: widget.userData['email']);
    telController = TextEditingController(text: widget.userData['telephone']);
    usernameController = TextEditingController(text: widget.userData['username']);
    competController = TextEditingController(
        text: (widget.userData['competences'] as List<dynamic>?)?.join(', ') ?? ''
    );
    etudeController= TextEditingController(text: widget.userData['niveau'] ?? '');
    dateController = TextEditingController(text: widget.userData['date_naissance'] ?? '');
    lieuController = TextEditingController(text: widget.userData['lieu_naissance'] ?? '');
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telController.dispose();
    usernameController.dispose();
    competController.dispose();
    etudeController.dispose();
    dateController.dispose();
    lieuController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final newUsername = usernameController.text.trim();

      // Vérifie si le nom d'utilisateur a changé
      if (newUsername != widget.userData['username']) {
        // Vérifie unicité
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: newUsername)
            .get();

        if (query.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ce nom d\'utilisateur existe déjà.')),
          );
          return;
        }

        // Vérifie format (lettres minuscules sans espace)
        final validUsername = RegExp(r'^[a-z0-9_]+$');
        if (!validUsername.hasMatch(newUsername)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le nom d\'utilisateur ne doit contenir que des lettres minuscules, des chiffres ou des underscores, sans espaces.')),
          );
          return;
        }
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'nom': nomController.text,
          'prenom': prenomController.text,
          'email': emailController.text,
          'telephone': telController.text,
          'username': newUsername,
          'competences': competController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'niveau': etudeController.text,
          'date_naissance': dateController.text,
          'lieu_naissance': lieuController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées !')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilEtud(
              userId: widget.userId,
              userData: {
                'nom': nomController.text,
                'prenom': prenomController.text,
                'email': emailController.text,
                'telephone': telController.text,
                'username': newUsername,
                'competences': competController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                'niveau': etudeController.text,
                'date_naissance': dateController.text,
                'lieu_naissance': lieuController.text,
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint("Erreur Firestore : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9DAFCB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Modifier le compte',
          style: TextStyle(
            fontFamily: 'Comic Sans MS',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Nom", nomController),
              _buildTextField("Prénom", prenomController),
              _buildTextField("Email", emailController),
              _buildTextField("Téléphone", telController),
              _buildTextField("Nom d'utilisateur", usernameController),
              _buildTextField("Compétences (séparées par des virgules)", competController),
              _buildTextField("Niveau d'étude", etudeController),
              _buildTextField("Date de naissance", dateController),
              _buildTextField("Lieu de naissance", lieuController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Enregistrer les modifications",
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

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Comic Sans MS'),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Champ requis';
          if (label == "Nom d'utilisateur") {
            final username = value.trim();
            final usernameRegex = RegExp(r'^[a-z0-9_]+$');
            if (!usernameRegex.hasMatch(username)) {
              return 'Uniquement minuscules, chiffres ou underscore.';
            }
          }
          return null;
        },
      ),
    );
  }
}
