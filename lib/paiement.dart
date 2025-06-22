import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'mesCoursEtud.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'theme.dart';

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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF3F51B5),
        elevation: 0,
        title: Text(
          'Paiement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF3F51B5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Prix : ${price.toStringAsFixed(2)} DT",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Détails du cours",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3F51B5),
                              ),
                            ),
                            Divider(height: 20),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    Text(
                      "Méthodes de paiement",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
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
                              onPressed: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  final uid = user.uid;
                                  final String courseIdToStore = originalCourseId;

                                  final purchaseData = Map<String, dynamic>.from(courseData);
                                  purchaseData['isPaid'] = true;
                                  purchaseData['userId'] = uid;
                                  purchaseData['courseIdOriginal'] = courseIdToStore;
                                  purchaseData['paymentMethod'] = 'Standard';

                                  await FirebaseFirestore.instance
                                      .collection('purchases')
                                      .add(purchaseData);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Cours acheté avec succès : $title"),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => MesCoursEtudPage()),
                                  );
                                }
                              },
                              style: AppTheme.primaryButtonStyle,
                              child: Text(
                                'Payer maintenant',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
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
                            child: ElevatedButton.icon(
                              onPressed: () => handleGooglePay(context, price, courseData),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                elevation: 2,
                              ),
                              icon: Image.asset(
                                'assets/google-pay-mark.png',
                                height: 24,
                                width: 50,
                              ),
                              label: Text(
                                'Payer avec Google Pay',
                                style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
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
    );
  }

  Future<void> handleGooglePay(BuildContext context, double amount, Map<String, dynamic> courseData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Afficher un message d'information pour l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Configuration de Google Pay en cours..."),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
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
        SnackBar(
          content: Text("Paiement réussi via Google Pay : ${courseData['title']}"),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MesCoursEtudPage()),
      );
    } catch (e) {
      print("Erreur Google Pay : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Échec du paiement avec Google Pay."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        )
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