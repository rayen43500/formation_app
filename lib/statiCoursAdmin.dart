import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:ly_na/ComptEtudiant.dart'; // adapte le chemin si besoin

class StatiCoursAdminPage extends StatefulWidget {
  final String courseId;

  const StatiCoursAdminPage({Key? key, required this.courseId}) : super(key: key);

  @override
  _StatiCoursAdminPageState createState() => _StatiCoursAdminPageState();
}

class _StatiCoursAdminPageState extends State<StatiCoursAdminPage> {
  int _selectedIndex = 0;

  static const TextStyle optionStyle =
  TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Widget buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Color(0xFFEAC11C),
          size: 24,
        );
      }),
    );
  }

  Widget _buildAvisEtCommentaires() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('purchases')
          .where('courseIdOriginal', isEqualTo: widget.courseId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error.toString()}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final purchases = snapshot.data!.docs;

        if (purchases.isEmpty) {
          return Center(child: Text('Aucun avis ou commentaire disponible.'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: purchases.length,
          itemBuilder: (context, index) {
            final purchase = purchases[index];
            final data = purchase.data() as Map<String, dynamic>?;

            if (data == null) return SizedBox();

            final rating = data['ratingEtudiant'];
            final userId = data['userId'];

            final rawCommentaires = data['commentaire'];
            final commentaires = (rawCommentaires is List)
                ? rawCommentaires
                .where((e) => e is Map<String, dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()
                : [];

            if ((rating == null || rating == 0) && commentaires.isEmpty) {
              return SizedBox();
            }

            return FutureBuilder<DocumentSnapshot>(
              future:
              FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox();
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return SizedBox();
                }

                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>;
                final nom = userData['nom'] ?? '';
                final prenom = userData['prenom'] ?? '';
                final fullName = '$nom $prenom';

                commentaires.sort((a, b) {
                  final dateA = a['createdAt'] is Timestamp
                      ? (a['createdAt'] as Timestamp).toDate()
                      : DateTime(0);
                  final dateB = b['createdAt'] is Timestamp
                      ? (b['createdAt'] as Timestamp).toDate()
                      : DateTime(0);
                  return dateB.compareTo(dateA);
                });

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne nom + étoiles à droite
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ComptesEtudiantsPage(userId: userId),
                                ),
                              );
                            },
                            child: Text(
                              fullName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                decoration: TextDecoration.none, // pas souligné
                              ),
                            ),
                          ),
                          if (rating != null && rating != 0)
                            buildRatingStars(rating),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Commentaires en dessous du nom
                      if (commentaires.isNotEmpty)
                        ...commentaires.map((comment) {
                          final text = comment['text'] ?? '';
                          final date = comment['createdAt'] is Timestamp
                              ? (comment['createdAt'] as Timestamp).toDate()
                              : null;
                          final formattedDate = date != null
                              ? DateFormat('dd MMM yyyy – HH:mm').format(date)
                              : 'Date inconnue';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  'Ajouté le $formattedDate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


  Widget _buildListeAchatsEtRevenu() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('purchases')
          .where('courseIdOriginal', isEqualTo: widget.courseId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error.toString()}'));
        }

        final purchases = snapshot.data!.docs;

        if (purchases.isEmpty) {
          return Center(child: Text('Aucun achat enregistré pour ce cours.'));
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.courseId)
              .get(),
          builder: (context, courseSnapshot) {
            if (courseSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
              return Center(child: Text('Cours introuvable.'));
            }

            final courseData =
            courseSnapshot.data!.data() as Map<String, dynamic>;
            final prix = courseData['price'] ?? 0;
            final revenuTotal = prix * purchases.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: purchases.length,
                    itemBuilder: (context, index) {
                      final purchase = purchases[index];
                      final data =
                          purchase.data() as Map<String, dynamic>? ?? {};
                      final userId = data['userId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return ListTile(
                              title: Text('Utilisateur inconnu'),
                            );
                          }

                          final userData = userSnapshot.data!.data()
                          as Map<String, dynamic>;
                          final nom = userData['nom'] ?? '';
                          final prenom = userData['prenom'] ?? '';

                          return ListTile(
                            leading: Icon(Icons.person),
                            title: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ComptesEtudiantsPage(userId: userId),
                                  ),
                                );
                              },
                              child: Text(
                                '$nom $prenom',
                                style: TextStyle(
                                    color: Colors.black),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '💰 Revenu total : $revenuTotal TND',
                    style: optionStyle.copyWith(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> get _widgetOptions => <Widget>[
    _buildAvisEtCommentaires(),
    _buildListeAchatsEtRevenu(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB),
      appBar: AppBar(
        backgroundColor: Color(0xFF9DAFCB),
        title: Text('Statistiques du Cours'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.comment),
            label: 'Avis & Commentaires',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
