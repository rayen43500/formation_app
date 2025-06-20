// gest_users.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detailEtud.dart';// Import de la page de détails de l'étudiant

class GestUsers extends StatefulWidget {
  const GestUsers({super.key});

  @override
  State<GestUsers> createState() => _GestUsersState();
}

class _GestUsersState extends State<GestUsers> {
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference _usersCollection =
  FirebaseFirestore.instance.collection('users');
  final Color primaryColor = const Color(0xFF9FB0CC);
  final Color linkColor = Colors.blue; // Couleur pour le nom d'utilisateur cliquable

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: const Text('Gestion des Étudiants'),
        backgroundColor: primaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
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
      body: Center(
        child: SingleChildScrollView(
          child: Theme(
            data: Theme.of(context).copyWith(
              dataTableTheme: DataTableThemeData(
                decoration: const BoxDecoration(
                  color: Colors.white38,
                ),
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Une erreur s\'est produite: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usersData = snapshot.data!.docs;
                final filteredUsers = usersData.where((doc) {
                  final userName = (doc.data() as Map<String, dynamic>)['username']
                      ?.toString()
                      .toLowerCase() ??
                      '';
                  return userName.contains(_searchController.text.toLowerCase());
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('Aucun étudiant trouvé.'));
                }

                return DataTable(
                  columnSpacing: 20.0,
                  dataRowMinHeight: 70.0,
                  dataRowMaxHeight: 90.0,
                  columns: const [
                    DataColumn(label: Text('Nom d\'utilisateur')),
                    DataColumn(label: Center(child: Text('Statut'))),
                    DataColumn(label: Center(child: Text('Action'))),
                  ],
                  rows: filteredUsers.map((doc) {
                    final userData = doc.data() as Map<String, dynamic>;
                    final username = userData['username'] as String;
                    final isActive = userData['estActif'] ?? true;

                    return DataRow(
                      key: ValueKey(doc.id),
                      cells: [
                        DataCell(
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailEtud(userId: doc.id, userData: userData) ,
                                ),
                              );
                            },
                            child: Text(
                              username,
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
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  size: 20.0,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  isActive ? 'Actif' : 'Bloqué',
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
                                    onPressed: () => _toggleBlock(doc.id, !isActive),
                                    icon: Icon(isActive ? Icons.lock : Icons.lock_open, size: 16.0),
                                    label: Text(isActive ? 'Bloquer' : 'Débloquer', style: const TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isActive ? Colors.white24 : Colors.lightBlue,
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
                                    onPressed: () => _deleteUser(doc.id),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _toggleBlock(String userId, bool newStatus) async {
    try {
      await _usersCollection.doc(userId).update({'estActif': newStatus});
    } catch (e) {
      print("Erreur lors de la mise à jour du statut: $e");
      // Gérer l'erreur
    }
  }

  void _deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      print("Erreur lors de la suppression de l'utilisateur: $e");
      // Gérer l'erreur
    }
  }
}