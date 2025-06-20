import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'acceuilFormateur.dart';
import 'login_page.dart'; // Assuming this is LoginScreen
import 'acceuilAdmin.dart';

class LoginFormateur extends StatefulWidget {
  @override
  _LoginFormateurState createState() => _LoginFormateurState();
}

class _LoginFormateurState extends State<LoginFormateur> {
  int _selectedIndex = 1; // 0 for Étudiant, 1 for Enseignant (default to Enseignant)
  bool _isPasswordVisible = false;
  bool _isCodeCoursVisible = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeCoursController = TextEditingController();

  Future<void> _sendResetPasswordEmail() async {
    try {
      var username = _usernameController.text.trim();
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nom d'utilisateur non trouvé.")),
        );
        return;
      }

      String email = snapshot.docs.first['email'];
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email de réinitialisation envoyé.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la réinitialisation.")),
      );
    }
  }// This method is now responsible for handling navigation bar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) { // If 'Étudiant' is selected
      Navigator.pushReplacement( // Use pushReplacement to avoid stacking login screens
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
    // If index is 1 (Enseignant), stay on this page.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Skill',
                      style: GoogleFonts.greatVibes(
                        fontSize: 48,
                        color: Color(0xFFB29245),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' Bridge',
                      style: GoogleFonts.greatVibes(
                        fontSize: 48,
                        color: Color(0xFFB29245),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'E-Learning',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Color(0xFF8D8B45),
                  ),
                ),
                const SizedBox(height: 20),
                // Removed the old tab buttons here, replaced by BottomNavigationBar
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bienvenue, connectez-vous :',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField('Nom d\'utilisateur', controller: _usernameController),
                const SizedBox(height: 10),
                _buildTextField('Mot de passe', controller: _passwordController, isPassword: true),
                const SizedBox(height: 10),
                _buildCodeCoursField(),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _sendResetPasswordEmail,
                    child: Text('Mot de passe oublié ?', style: TextStyle(decoration: TextDecoration.underline, color: Colors.black54)),
                  ),
                ),
                const SizedBox(height: 10),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Étudiant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Enseignant',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueGrey, // Added for better visual distinction
        onTap: _onItemTapped,
        backgroundColor: Colors.white70,
      ),
    );
  }

  Widget _buildCodeCoursField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _codeCoursController,
            obscureText: !_isCodeCoursVisible,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Code Cours (5 caractères)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            maxLength: 5,
          ),
        ),
        IconButton(
          icon: Icon(
            _isCodeCoursVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black54,
          ),
          onPressed: () {
            setState(() {
              _isCodeCoursVisible = !_isCodeCoursVisible;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTextField(String hintText, {bool isPassword = false, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black54,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _login,
        child: Text(
          'Se connecter',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final codeCours = _codeCoursController.text.trim();

    if (username.isEmpty || password.isEmpty || codeCours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    if (username == 'admin' && password == 'skillbridge' && codeCours == '12345') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccueilAdmin()),
      );
      return;
    }
    try {
      // Rechercher le formateur par username
      final snapshot = await FirebaseFirestore.instance
          .collection('formateurs')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nom d'utilisateur introuvable.")),
        );
        return;
      }

      final data = snapshot.docs.first.data();
      final email = data['email'];
      final codeStocke = data['code_cours'];

      if (codeCours != codeStocke) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Code cours incorrect.")),
        );
        return;
      }

      // Connexion Firebase Auth avec email et mot de passe
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Connexion réussie
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccueilFormateur()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    }
  }
}