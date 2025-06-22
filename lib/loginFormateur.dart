import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'acceuilFormateur.dart';
import 'login_page.dart'; // Assuming this is LoginScreen
import 'acceuilAdmin.dart';
import 'theme.dart';

class LoginFormateur extends StatefulWidget {
  @override
  _LoginFormateurState createState() => _LoginFormateurState();
}

class _LoginFormateurState extends State<LoginFormateur> {
  int _selectedIndex = 1; // 0 for Étudiant, 1 for Enseignant (default to Enseignant)
  bool _isPasswordVisible = false;
  bool _isCodeCoursVisible = false;
  bool _isLoading = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeCoursController = TextEditingController();

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

  Future<void> _sendResetPasswordEmail() async {
    if (_usernameController.text.isEmpty) {
      _showErrorSnackBar("Veuillez entrer votre nom d'utilisateur");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      var username = _usernameController.text.trim();
      var snapshot = await FirebaseFirestore.instance
          .collection('formateurs')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _showErrorSnackBar("Nom d'utilisateur non trouvé.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String email = snapshot.docs.first['email'];
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _showSuccessSnackBar("Email de réinitialisation envoyé à $email");
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar("Erreur lors de la réinitialisation.");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // This method is now responsible for handling navigation bar taps
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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo et titre
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Skill',
                            style: GoogleFonts.greatVibes(
                              fontSize: 48,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' Bridge',
                            style: GoogleFonts.greatVibes(
                              fontSize: 48,
                              color: AppTheme.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'E-Learning Platform',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.grey[700],
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Formulaire de connexion
                Container(
                  padding: EdgeInsets.all(20),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Connexion Enseignant',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 38.0),
                        child: Text(
                          'Accédez à votre espace enseignant',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      
                      _buildTextField('Nom d\'utilisateur', controller: _usernameController),
                      SizedBox(height: 16),
                      _buildTextField('Mot de passe', controller: _passwordController, isPassword: true),
                      SizedBox(height: 16),
                      _buildCodeCoursField(),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _sendResetPasswordEmail,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 15),
                      _buildLoginButton(),
                      
                      SizedBox(height: 20),
                      
                      // Information sur le code cours
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Le code cours est fourni par l\'administrateur lors de votre inscription.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
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
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildCodeCoursField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5.0, bottom: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.vpn_key_outlined,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              SizedBox(width: 5),
              Text(
                "Code Cours",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                " *",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
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
          child: TextField(
            controller: _codeCoursController,
            obscureText: !_isCodeCoursVisible,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Entrez le code à 5 caractères',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.primaryColor),
              suffixIcon: IconButton(
                icon: Icon(
                  _isCodeCoursVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () => setState(() => _isCodeCoursVisible = !_isCodeCoursVisible),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
              ),
            ),
            maxLength: 5,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String hintText, {bool isPassword = false, required TextEditingController controller}) {
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
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            isPassword ? Icons.lock_outline : Icons.person_outline, 
            color: AppTheme.primaryColor
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
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
    );
  }

  Widget _buildLoginButton() {
    return Container(
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
        style: AppTheme.primaryButtonStyle,
        onPressed: _isLoading ? null : _login,
        child: _isLoading 
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Se connecter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final codeCours = _codeCoursController.text.trim();

    if (username.isEmpty || password.isEmpty || codeCours.isEmpty) {
      _showErrorSnackBar('Veuillez remplir tous les champs.');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (username == 'admin' && password == 'skillbridge' && codeCours == '12345') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccueilAdmin()),
        );
        return;
      }
      
      // Rechercher le formateur par username
      final snapshot = await FirebaseFirestore.instance
          .collection('formateurs')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _showErrorSnackBar("Nom d'utilisateur introuvable.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.docs.first.data();
      final email = data['email'];
      final codeStocke = data['code_cours'];

      if (codeCours != codeStocke) {
        _showErrorSnackBar("Code cours incorrect.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Connexion Firebase Auth avec email et mot de passe
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _showSuccessSnackBar("Connexion réussie!");
      
      // Connexion réussie
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccueilFormateur()),
      );
    } catch (e) {
      _showErrorSnackBar("Erreur : ${e.toString()}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Afficher un message d'information
      _showSuccessSnackBar("Connexion Google en cours...");
      
      // Simuler le processus de connexion Google pour les enseignants
      await Future.delayed(Duration(seconds: 2));
      
      // Ici, vous pourriez implémenter la vérification que l'utilisateur Google
      // est bien un enseignant enregistré dans votre base de données
      
      _showSuccessSnackBar("Connexion réussie!");
      
      // Redirection vers la page d'accueil formateur
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AccueilFormateur()),
      );
    } catch (e) {
      _showErrorSnackBar("Erreur lors de la connexion Google");
      setState(() {
        _isLoading = false;
      });
    }
  }
}