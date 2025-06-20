import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Détail cours admin.dart';
import 'statiCoursAdmin.dart';

class GestCoursPage extends StatefulWidget {
  @override
  _GestCoursPageState createState() => _GestCoursPageState();
}

class _GestCoursPageState extends State<GestCoursPage> {
  String selectedCategory = '';
  String searchText = '';
  List<QueryDocumentSnapshot> categoriesList = [];

  @override
  void initState() {
    super.initState();
    _loadInitialCategory();
  }

  Future<void> _loadInitialCategory() async {
    final snapshot = await FirebaseFirestore.instance.collection('categories').get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        categoriesList = snapshot.docs;
        selectedCategory = categoriesList.first['nom'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9FB0CC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9FB0CC),
        elevation: 0,
        title: const Text(
          'Gestion des Cours',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Comic Sans MS',
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un cours...',
                  hintStyle: const TextStyle(fontFamily: 'Comic Sans MS'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: const Text(
                'Catégories:',
                style: TextStyle(
                  fontFamily: 'Comic Sans MS',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Une erreur s\'est produite'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Aucune catégorie disponible.'));
                  }

                  final categories = snapshot.data!.docs;

                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: categories.map((DocumentSnapshot document) {
                      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                      String categoryName = data['nom'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = categoryName;
                            });
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: selectedCategory == categoryName
                                ? Colors.grey
                                : Colors.white38,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            categoryName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Comic Sans MS',
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('category', isEqualTo: selectedCategory)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allCourses = snapshot.data!.docs;
                  final filteredCourses = allCourses.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title']?.toLowerCase() ?? '';
                    return title.contains(searchText.toLowerCase());
                  }).toList();

                  if (filteredCourses.isEmpty) {
                    return const Center(child: Text('Aucun cours trouvé dans cette catégorie.'));
                  }

                  return ListView.builder(
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final courseDoc = filteredCourses[index];
                      return _CourseCard(doc: courseDoc);
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

class _CourseCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const _CourseCard({required this.doc});

  @override
  _CourseCardState createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  String? _status;
  int? _rating;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _status = (data['status'] is String) ? data['status'] : 'En attente';
    _rating = (data['rating'] is int) ? data['rating'] : 0;
  }

  Future<void> _updateCourseStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.doc.id)
          .set({'status': newStatus}, SetOptions(merge: true));
      setState(() {
        _status = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'Le statut du cours a été mis à jour à : $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de la mise à jour du statut.')),
      );
    }
  }

  Future<void> _updateRating() async {
    final currentDocSnapshot = await FirebaseFirestore.instance.collection(
        'courses').doc(widget.doc.id).get();
    final currentData = currentDocSnapshot.data();
    int actualRating = (currentData?['rating'] is int)
        ? currentData!['rating']
        : 0;
    int newRating = (actualRating + 1) % 6;

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.doc.id)
          .set({'rating': newRating}, SetOptions(merge: true));
      setState(() {
        _rating = newRating;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La note a été mise à jour à : $newRating')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de la mise à jour de la note.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '';
    final price = (data['price'] ?? 0).toDouble();
    final instructorName = data['instructorName'] ?? 'Instructeur inconnu';
    final currentStatusDisplay = _status ?? 'Inconnu';
    final currentRatingDisplay = _rating ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailCoursAdmin(courseId: widget.doc.id),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 8.0, bottom: 0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(instructorName,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currentStatusDisplay,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: currentStatusDisplay == 'Validé'
                                  ? Colors.green
                                  : currentStatusDisplay == 'Refusé'
                                  ? Colors.red
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (index) =>
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.star,
                                        color: index < currentRatingDisplay
                                            ? Color(0xFFFBC02D)
                                            : Colors.black, size: 24),
                                    Icon(Icons.star_border, color: Colors.white,
                                        size: 22),
                                  ],
                                )),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: _updateRating,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black),
                              child: const Text("Mettre à niveau",
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 10)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 120,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StatiCoursAdminPage(
                                            courseId: widget.doc.id),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black),
                              child: const Text("Voir statistiques",
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Prix : ${price.toStringAsFixed(2)} DT',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _updateCourseStatus('Validé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      minimumSize: const Size(0, 0),
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                        "Valider", style: TextStyle(color: Colors.black)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _updateCourseStatus('En attente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      minimumSize: const Size(0, 0),
                    ),
                    icon: const Icon(Icons.timer, size: 20),
                    label: const Text(
                        "En attente", style: TextStyle(color: Colors.black)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _updateCourseStatus('Refusé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      minimumSize: const Size(0, 0),
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text(
                        "Refuser", style: TextStyle(color: Colors.black)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}