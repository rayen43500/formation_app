import 'package:flutter/material.dart';
import 'ajoutForm.dart';
import 'detailForm.dart'; // Import de la page de détails
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String nom;
  final String prenom;
  bool estActif;
  final Map<String, dynamic> data; // Pour stocker toutes les données du formateur

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    this.estActif = true,
    required this.data,
  });
}

class GestForm extends StatefulWidget {
  const GestForm({super.key});

  @override
  State<GestForm> createState() => _GestFormState();
}

class _GestFormState extends State<GestForm> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color primaryColor = const Color(0xFF9FB0CC);
  final Color linkColor = Colors.blue; // Couleur pour le nom cliquable

  Stream<List<User>> _formateursStream() {
    return _firestore.collection('formateurs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return User(
          id: doc.id,
          nom: data['nom'] ?? '',
          prenom: data['prenom'] ?? '',
          estActif: data['estActif'] ?? true, // Récupérer l'état actif depuis Firestore
          data: data, // Stocker toutes les données
        );
      }).toList();
    });
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchController.text.isEmpty) {
      return users;
    }
    return users.where((user) =>
        (user.nom.toLowerCase() + ' ' + user.prenom.toLowerCase())
            .contains(_searchController.text.toLowerCase())).toList();
  }

  Future<void> _toggleBlock(String userId, bool currentActive) async {
    try {
      await _firestore.collection('formateurs').doc(userId).update({
        'estActif': !currentActive,
      });
    } catch (e) {
      print('Erreur lors du changement de statut: $e');
      // Gérer l'erreur ici (afficher un message à l'utilisateur, etc.)
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('formateurs').doc(userId).delete();
    } catch (e) {
      print('Erreur lors de la suppression du formateur: $e');
      // Gérer l'erreur ici
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text('Gestion des Formateurs'),
        backgroundColor: primaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un formateur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<User>>(
        stream: _formateursStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Une erreur s\'est produite: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final formateurs = snapshot.data ?? [];
          final filteredFormateurs = _filterUsers(formateurs);

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dataTableTheme: DataTableThemeData(
                          decoration: const BoxDecoration(
                            color: Colors.white38,
                          ),
                        ),
                      ),
                      child: DataTable(
                        columnSpacing: 20.0,
                        dataRowMinHeight: 70.0,
                        dataRowMaxHeight: 90.0,
                        columns: const [
                          DataColumn(label: Text('Nom du Formateur')),
                          DataColumn(label: Center(child: Text('Statut'))),
                          DataColumn(label: Center(child: Text('Action'))),
                        ],
                        rows: filteredFormateurs.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailForm(
                                          formateurId: user.id,
                                          formData: user.data,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '${user.nom} ${user.prenom}',
                                    style: TextStyle(
                                      color: linkColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 10.0),
                                      Icon(
                                        user.estActif ? Icons.check_circle : Icons.cancel,
                                        size: 20.0,
                                        color: user.estActif ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(height: 6.0),
                                      Text(
                                        user.estActif ? 'Actif' : 'Bloqué',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 10.0),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const SizedBox(height: 6.0),
                                      SizedBox(
                                        height: 30.0,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _toggleBlock(user.id, user.estActif),
                                          icon: Icon(user.estActif ? Icons.lock : Icons.lock_open, size: 16.0),
                                          label: Text(user.estActif ? 'Bloquer' : 'Débloquer', style: const TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: user.estActif ? Colors.white24 : Colors.lightBlue,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),
                                      SizedBox(
                                        height: 30.0,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _deleteUser(user.id),
                                          icon: const Icon(Icons.delete, size: 16.0),
                                          label: const Text('Supprimer', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[400],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AjoutForm()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un Formateur'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}