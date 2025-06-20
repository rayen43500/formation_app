import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class GestCateg extends StatefulWidget {
  @override
  _GestCategState createState() => _GestCategState();
}

class _GestCategState extends State<GestCateg> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final CollectionReference _catRef =
  FirebaseFirestore.instance.collection('categories');

  IconData getIconForCategory(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('programmation')) return Icons.code;
    if (nameLower.contains('design')) return Icons.palette;
    if (nameLower.contains('marketing')) return Icons.campaign;
    if (nameLower.contains('langue')) return Icons.language;
    if (nameLower.contains('business')) return Icons.business_center;
    if (nameLower.contains('science') || nameLower.contains('math'))
      return Icons.science;
    return Icons.folder;
  }

  void _afficherMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _ajouterCategorie() async {
    final String newCat = _controller.text.trim();
    if (newCat.isEmpty) return;

    final existing = await _catRef
        .where('nom', isEqualTo: newCat)
        .get();

    if (existing.docs.isNotEmpty) {
      _afficherMessage('Cette catégorie est déjà existe.');
      return;
    }

    await _catRef.add({'nom': newCat});
    _controller.clear();
  }

  void _supprimerCategorie(String docId) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirmation"),
        content: Text("Supprimer cette catégorie ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Supprimer")),
        ],
      ),
    );

    if (confirm == true) {
      await _catRef.doc(docId).delete();
    }
  }

  void _editerCategorie(String docId, String ancienNom) {
    final TextEditingController editController = TextEditingController(text: ancienNom);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Modifier la catégorie"),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(labelText: "Nouveau nom"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          TextButton(
            onPressed: () async {
              final nouveauNom = editController.text.trim();
              if (nouveauNom.isNotEmpty) {
                final existing = await _catRef
                    .where('nom', isEqualTo: nouveauNom)
                    .get();

                if (existing.docs.isNotEmpty && nouveauNom != ancienNom) {
                  _afficherMessage('Une catégorie avec ce nom existe déjà.');
                  return;
                }
                await _catRef.doc(docId).update({'nom': nouveauNom});
              }
              Navigator.pop(context);
            },
            child: Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB),
      appBar: AppBar(
        title: Text('Gestion des Catégories'),
        backgroundColor: Color(0xFF9DAFCB),
        elevation: 0, // Supprime l'ombre sous l'AppBar pour une apparence plus plate
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Alignement à gauche
          children: [
            // Titre aligné à gauche (peut être supprimé si vous ne le souhaitez plus)
            // Text(
            //   "Gestion des catégories",
            //   style: TextStyle(
            //     fontSize: 24,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.black, // Ajustez la couleur selon le besoin
            //   ),
            //   textAlign: TextAlign.left, // Assurez-vous que le texte est aligné à gauche
            // ),
            // SizedBox(height: 20), // Espacement après le titre (peut être supprimé)

            // Recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            SizedBox(height: 20),

            // Ajout
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nouvelle catégorie',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _ajouterCategorie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                  ),
                  child: Text(
                    'Ajouter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Liste des catégories
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _catRef.orderBy('nom').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());

                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final nom = doc['nom'].toString().toLowerCase();
                    return nom.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(child: Text("Aucune catégorie trouvée."));
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final nom = doc['nom'];

                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: Card(
                          child: ListTile(
                            leading: Icon(getIconForCategory(nom),
                                color: Color(0xFFB29245)),
                            title: Text(nom),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editerCategorie(doc.id, nom),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _supprimerCategorie(doc.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}