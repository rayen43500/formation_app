import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'registration_page.dart';
import 'loginFormateur.dart';
import 'acceuilEtudiant.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedIndex = 0; // 0 for Étudiant, 1 for Enseignant
  bool _isPasswordVisible = false;
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  bool _validatePassword(String password) => password.length >= 8;

  Future<void> _loginWithUsernameAndPassword() async {
    if (!_validatePassword(passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le mot de passe doit contenir au moins 8 caractères.')),
      );
      return;
    }

    String username = usernameController.text.trim();
    String password = passwordController.text;

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nom d'utilisateur introuvable.")),
        );
        return;
      }

      String email = snapshot.docs.first['email'];

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccueilEtudiantPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connexion échouée. Vérifiez vos identifiants.")),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccueilEtudiantPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion Google.")),
      );
    }
  }

  Future<void> _loginWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken;
        final credential = FacebookAuthProvider.credential(accessToken!.token);

        await FirebaseAuth.instance.signInWithCredential(credential);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccueilEtudiantPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connexion Facebook échouée.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur Facebook.")),
      );
    }
  }

  Future<void> _sendResetPasswordEmail() async {
    try {
      var username = usernameController.text.trim();
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
  }

  Widget _buildTextField(String hintText, {TextEditingController? controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPasswordField(String hintText) {
    return TextField(
      controller: passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildButton(String text, Color color, Color textColor, [VoidCallback? onPressed, double? width]) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed ?? () {},
        child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String text, Color color, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.grey[300],
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(text, style: TextStyle(color: Colors.black)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginFormateur()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Skill', style: GoogleFonts.greatVibes(fontSize: 48, color: Color(0xFFB29245), fontWeight: FontWeight.bold)),
                  Text(' Bridge', style: GoogleFonts.greatVibes(fontSize: 48, color: Color(0xFFB29245), fontWeight: FontWeight.bold)),
                ],
              ),
              Text('E-Learning', style: GoogleFonts.roboto(fontSize: 18, color: Color(0xFF8D8B45))),
              SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: Text('Bienvenue, connectez-vous :', style: TextStyle(color: Colors.black))),
              SizedBox(height: 10),
              _buildTextField('Nom d\'utilisateur', controller: usernameController),
              SizedBox(height: 10),
              _buildPasswordField('Mot de passe'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _sendResetPasswordEmail,
                  child: Text('Mot de passe oublié ?', style: TextStyle(decoration: TextDecoration.underline, color: Colors.black54)),
                ),
              ),
              _buildButton('Se connecter', Colors.blue, Colors.white, _loginWithUsernameAndPassword, 300.0),
              SizedBox(height: 10),
              Text('Ou', style: TextStyle(fontSize: 16)),
              SizedBox(height: 5),
              _buildButton('S\'inscrire', Colors.green, Colors.white, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationPage()));
              }, 200), // Reduced width for 'S'inscrire' button
              SizedBox(height: 10),
              IntrinsicWidth( // Align social buttons vertically
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 250), // Set a minimum width for consistent sizing
                      child: _buildSocialButton(FontAwesomeIcons.facebook, 'Continuer avec Facebook', Colors.blue, _loginWithFacebook),
                    ),
                    SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 250), // Apply the same minimum width
                      child: _buildSocialButton(FontAwesomeIcons.google, 'Continuer avec Google', Colors.red, _loginWithGoogle),
                    ),
                  ],
                ),
              ),
            ],
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
        selectedItemColor: Colors.blueGrey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white70,
      ),
    );
  }
}