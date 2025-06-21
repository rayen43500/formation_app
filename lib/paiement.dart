import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'mesCoursEtud.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaiementPage extends StatelessWidget {
  final Map<String, dynamic> courseData;
  final String originalCourseId;

  const PaiementPage({
    super.key,
    required this.courseData,
    required this.originalCourseId,
  });

  @override
  Widget build(BuildContext context) {
    final title = courseData['title'] ?? 'Cours';
    final description = courseData['description'] ?? 'Pas de description';
    final price = (courseData['price'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB),
      appBar: AppBar(
        backgroundColor: Color(0xFF9DAFCB),
        title: Text('Paiement $title'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vous êtes sur le point d'acheter le cours :",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 12),
            Text(
              'Prix : ${price.toStringAsFixed(2)} DT',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            Spacer(),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final uid = user.uid;
                        final String courseIdToStore = originalCourseId;

                        final purchaseData = Map<String, dynamic>.from(courseData);
                        purchaseData['isPaid'] = true;
                        purchaseData['userId'] = uid;
                        purchaseData['courseIdOriginal'] = courseIdToStore;

                        await FirebaseFirestore.instance
                            .collection('purchases')
                            .add(purchaseData);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Cours acheté avec succès : $title")),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MesCoursEtudPage()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: Text(
                      'Payer maintenant',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () => handleGooglePay(context, price, courseData),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      backgroundColor: Colors.white,
                    ),
                    icon: Image.network(
                      'https://developers.google.com/static/pay/api/images/brand-guidelines/google-pay-mark.png',
                      height: 24,
                      width: 24,
                    ),
                    label: Text(
                      'Payer avec Google Pay',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> handleGooglePay(BuildContext context, double amount, Map<String, dynamic> courseData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Afficher un message d'information pour l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Configuration de Google Pay en cours..."))
      );
      
      // Simuler le processus de paiement (à remplacer par l'intégration réelle)
      await Future.delayed(Duration(seconds: 2));
      
      // Marquer l'achat comme payé dans Firestore
      final purchaseData = Map<String, dynamic>.from(courseData);
      purchaseData['isPaid'] = true;
      purchaseData['userId'] = user.uid;
      purchaseData['courseIdOriginal'] = originalCourseId;
      purchaseData['paymentMethod'] = 'Google Pay';

      await FirebaseFirestore.instance
          .collection('purchases')
          .add(purchaseData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Paiement réussi via Google Pay : ${courseData['title']}"))
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MesCoursEtudPage()),
      );
    } catch (e) {
      print("Erreur Google Pay : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec du paiement avec Google Pay."))
      );
    }
  }

/*
Pour activer Google Pay complètement, décommentez ce code et ajoutez la dépendance flutter_stripe au pubspec.yaml

Future<void> handleGooglePay(BuildContext context, double amount, Map<String, dynamic> courseData) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // Étape 1 : Appel au backend local via IP locale
    final response = await http.post(
      Uri.parse('http://192.168.1.103:5001/version2-a3872/us-central1/createPaymentIntent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': (amount * 100).toInt(), // en centimes
        'currency': 'usd',
      }),
    );

    final data = jsonDecode(response.body);
    final clientSecret = data['clientSecret'];

    // Étape 2 : Initialiser Google Pay
    await Stripe.instance.initGooglePay(
      GooglePayInitParams(
        merchantName: 'Skill Bridge',
        countryCode: 'US',
        testEnv: true,
      ),
    );

    // Étape 3 : Lancer le paiement Google Pay
    await Stripe.instance.presentGooglePay(
      PresentGooglePayParams(
        clientSecret: clientSecret,
        currencyCode: 'usd',
      ),
    );

    // Étape 4 : Marquer l'achat comme payé dans Firestore
    final purchaseData = Map<String, dynamic>.from(courseData);
    purchaseData['isPaid'] = true;
    purchaseData['userId'] = user.uid;
    purchaseData['courseIdOriginal'] = originalCourseId;

    await FirebaseFirestore.instance
        .collection('purchases')
        .add(purchaseData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Paiement réussi : ${courseData['title']}")),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MesCoursEtudPage()),
    );
  } catch (e) {
    print("Erreur Google Pay : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec du paiement.")),
    );
  }
}
*/
} 