import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'DetailForm.dart';

class EditFormPage extends StatefulWidget {
  final String formateurId;
  final Map<String, dynamic> formData;

  const EditFormPage({super.key, required this.formateurId, required this.formData});

  @override
  State<EditFormPage> createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController emailController;
  late TextEditingController telController;
  late TextEditingController usernameController;
  late TextEditingController codeController;
  late TextEditingController dateController;
  late TextEditingController lieuController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.formData['nom']);
    prenomController = TextEditingController(text: widget.formData['prenom']);
    emailController = TextEditingController(text: widget.formData['email']);
    telController = TextEditingController(text: widget.formData['telephone']);
    usernameController = TextEditingController(text: widget.formData['username']);
    codeController = TextEditingController(text: widget.formData['code_cours']);
    dateController = TextEditingController(text: widget.formData['date_naissance']);
    lieuController = TextEditingController(text: widget.formData['lieu_naissance']);
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telController.dispose();
    usernameController.dispose();
    codeController.dispose();
    dateController.dispose();
    lieuController.dispose();
    super.dispose();
  }

  Future<bool> isUsernameValidAndUnique(String username) async {
    final RegExp regex = RegExp(r'^[a-z0-9_]+$');

    if (!regex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le nom d'utilisateur ne doit contenir que des lettres minuscules, chiffres ou '_' sans espaces.")),
      );
      return false;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('formateurs')
        .where('username', isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty &&
        querySnapshot.docs.first.id != widget.formateurId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ce nom d'utilisateur est déjà utilisé.")),
      );
      return false;
    }

    return true;
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final username = usernameController.text.trim();

      if (!await isUsernameValidAndUnique(username)) {
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('formateurs').doc(widget.formateurId).update({
          'nom': nomController.text,
          'prenom': prenomController.text,
          'email': emailController.text,
          'telephone': telController.text,
          'username': username,
          'password': codeController.text,
          'date_naissance': dateController.text,
          'lieu_naissance': lieuController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modifications enregistrées !')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailForm(
              formateurId: widget.formateurId,
              formData: {
                'nom': nomController.text,
                'prenom': prenomController.text,
                'email': emailController.text,
                'telephone': telController.text,
                'username': username,
                'code_cours': codeController.text,
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
          'Modifier le Formateur',
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
              _buildPasswordField("Code cours", codeController),
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
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Comic Sans MS'),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Champ requis';
          return null;
        },
      ),
    );
  }
}
