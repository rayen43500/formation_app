// Importation des packages nécessaires
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Pour utiliser des polices personnalisées
import 'package:firebase_auth/firebase_auth.dart'; // Pour la gestion de l'authentification Firebase

// Importation des pages internes liées à la gestion
import 'gestCours.dart'; // Page de gestion des cours
import 'gestUsers.dart'; // Page de gestion des étudiants
import 'gestCateg.dart'; // Page de gestion des catégories
import 'gestForm.dart'; // Page de gestion des formateurs
import 'login_page.dart'; // Page de connexion (utilisée après la déconnexion)

class AccueilAdmin extends StatelessWidget {
  // Interface principale pour l'administrateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB), // Couleur d’arrière-plan de la page
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0), // Marge horizontale de 20px
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centrer les éléments verticalement
          children: [
            // Titre de l'application
            Text(
              'Skill Bridge',
              style: GoogleFonts.greatVibes( // Police stylisée
                fontSize: 48,
                color: Color(0xFFB29245),
                fontWeight: FontWeight.bold,
              ),
            ),
            // Slogan ou description secondaire
            Text(
              'E-Learning',
              style: GoogleFonts.roboto( // Police plus simple
                fontSize: 18,
                color: Color(0xFF8D8B45),
              ),
            ),
            const SizedBox(height: 40), // Espace vertical

            // Bouton pour accéder à la gestion des étudiants
            _buildButton('Gestion des Étudiants', Colors.grey, Colors.black, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GestUsers()), // Navigation vers la page des étudiants
              );
            }),

            const SizedBox(height: 20), // Espace entre les boutons

            // Bouton pour accéder à la gestion des formateurs
            _buildButton('Gestion des Formateurs', Colors.grey, Colors.black, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GestForm()), // Navigation vers la page des formateurs
              );
            }),

            const SizedBox(height: 20),

            // Bouton pour accéder à la gestion des catégories de cours
            _buildButton('Gestion des Catégories', Colors.grey, Colors.black, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GestCateg()), // Navigation vers la page des catégories
              );
            }),

            const SizedBox(height: 20),

            // Bouton pour accéder à la gestion des cours
            _buildButton('Gestion des Cours', Colors.grey, Colors.black, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GestCoursPage()), // Navigation vers la page des cours
              );
            }),

            const SizedBox(height: 20),

            // Bouton pour se déconnecter de l'application
            _buildButton('Déconnexion', Colors.grey, Colors.black, () async {
              // Boîte de dialogue de confirmation avant déconnexion
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirmation"),
                  content: const Text("Voulez-vous vraiment vous déconnecter ?"),
                  actions: [
                    // Bouton pour annuler la déconnexion
                    TextButton(
                      child: const Text("Annuler"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    // Bouton pour confirmer la déconnexion
                    TextButton(
                      child: const Text("Se déconnecter"),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              // Si l'utilisateur confirme, on le déconnecte
              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut(); // Déconnexion Firebase

                // Navigation vers la page de connexion en supprimant l'historique de navigation
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (Route<dynamic> route) => false,
                );

                // Affichage d'un message de succès
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Déconnecté avec succès")),
                );
              }
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Méthode utilitaire pour construire les boutons du menu admin
  Widget _buildButton(String text, Color buttonColor, Color borderColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, // Le bouton prend toute la largeur disponible
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: buttonColor, // Couleur de fond
          padding: EdgeInsets.symmetric(vertical: 16), // Hauteur interne du bouton
          side: BorderSide(color: borderColor, width: 2), // Bordure
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Coins arrondis
          ),
        ),
        onPressed: onPressed, // Action à exécuter lors du clic
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.black), // Style du texte
        ),
      ),
    );
  }
}
 