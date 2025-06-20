import 'package:flutter/material.dart'; // Interface utilisateur Flutter
import 'package:cloud_firestore/cloud_firestore.dart'; // Base de données Firestore
import 'dart:io'; // Manipulation de fichiers
import 'package:flutter_file_dialog/flutter_file_dialog.dart'; // Boîte de dialogue pour choisir des fichiers
import 'package:firebase_auth/firebase_auth.dart'; // Authentification Firebase
import 'package:http/http.dart' as http; // Requêtes HTTP
import 'dart:convert'; // Conversion JSON

class AjoutCoursPage extends StatefulWidget {
  @override
  _AjoutCoursPageState createState() => _AjoutCoursPageState();
}

class _AjoutCoursPageState extends State<AjoutCoursPage> {
  // Contrôleurs pour les champs de saisie
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Catégorie sélectionnée
  String? _selectedCategory;

  // Listes de fichiers PDF et vidéos ajoutés
  List<Map<String, dynamic>> _pdfs = [];
  List<Map<String, dynamic>> _videos = [];

  // Référence à la collection "categories" dans Firestore
  final CollectionReference _categoryRef =
  FirebaseFirestore.instance.collection('categories');

  // Récupère toutes les catégories depuis Firestore
  Future<List<String>> _getCategories() async {
    final querySnapshot = await _categoryRef.get();
    return querySnapshot.docs.map((doc) => doc['nom'] as String).toList();
  }

  // Vérifie si le formulaire est valide
  bool get _isFormValid =>
      _titleController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _priceController.text.isNotEmpty &&
          _selectedCategory != null;

  // Ajout d'un fichier PDF avec titre
  Future<void> _addPDF() async {
    final result = await FlutterFileDialog.pickFile(); // Choix du fichier

    if (result != null && result.endsWith('.pdf')) {
      final titleController = TextEditingController();

      // Boîte de dialogue pour entrer le titre
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Titre du PDF"),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: "Titre"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler")),
            TextButton(
                onPressed: () {
                  setState(() {
                    // Ajoute le fichier PDF avec son titre à la liste
                    _pdfs.add({
                      'file': File(result),
                      'title': titleController.text.trim()
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text("Ajouter"))
          ],
        ),
      );
    } else {
      // Affiche une erreur si le fichier n'est pas un PDF
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier PDF.')),
      );
    }
  }

  // Ajout d'une vidéo avec titre
  Future<void> _addVideo() async {
    final result = await FlutterFileDialog.pickFile(); // Choix du fichier

    if (result != null &&
        (result.endsWith('.mp4') || result.endsWith('.mov'))) {
      final titleController = TextEditingController();

      // Boîte de dialogue pour entrer le titre
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Titre de la Vidéo"),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: "Titre"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler")),
            TextButton(
                onPressed: () {
                  setState(() {
                    // Ajoute la vidéo avec son titre à la liste
                    _videos.add({
                      'file': File(result),
                      'title': titleController.text.trim()
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text("Ajouter"))
          ],
        ),
      );
    } else {
      // Affiche une erreur si le fichier n'est pas une vidéo valide
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une vidéo valide.')),
      );
    }
  }

  // Upload d'un fichier sur Cloudinary (Cloud)
  Future<String> uploadFileToStorage(String folder, File file) async {
    try {
      final cloudName = 'deltanzkn';
      final uploadPreset = 'skillbridge';

      // Détermine l'URL API selon le type de fichier
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/${folder == 'videos' ? 'video' : 'raw'}/upload');

      // Crée la requête POST avec le fichier
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        final data = json.decode(res.body);
        return data['secure_url']; // Retourne l'URL publique
      } else {
        throw Exception("Échec du téléchargement");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sauvegarde du cours dans Firestore
  Future<void> _saveCourse() async {
    if (_isFormValid) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final instructorId = user?.uid;
        String instructorName = 'Formateur Inconnu';

        // Récupère les infos du formateur
        if (instructorId != null) {
          final instructorSnapshot = await FirebaseFirestore.instance
              .collection('formateurs')
              .doc(instructorId)
              .get();

          if (instructorSnapshot.exists) {
            final instructorData = instructorSnapshot.data();
            instructorName =
            '${instructorData?['nom'] ?? ''} ${instructorData?['prenom'] ?? ''}';
          }
        }

        // Upload des fichiers PDF
        List<Map<String, String>> pdfUrls = [];
        for (var pdf in _pdfs) {
          final url = await uploadFileToStorage('raw', pdf['file']);
          pdfUrls.add({'title': pdf['title'], 'url': url});
        }

        // Upload des vidéos
        List<Map<String, String>> videoUrls = [];
        for (var vid in _videos) {
          final url = await uploadFileToStorage('videos', vid['file']);
          videoUrls.add({'title': vid['title'], 'url': url});
        }

        // Prépare les données du cours
        final courseData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'category': _selectedCategory,
          'participants': 0,
          'instructorId': instructorId,
          'instructorName': instructorName,
          'createdAt': FieldValue.serverTimestamp(),
          'pdfs': pdfUrls,
          'videos': videoUrls,
        };

        // Ajoute le cours à Firestore
        await FirebaseFirestore.instance.collection('courses').add(courseData);

        // Affiche une confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours ajouté avec succès!')),
        );

        // Réinitialise le formulaire
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        setState(() {
          _selectedCategory = null;
          _pdfs = [];
          _videos = [];
        });
      } catch (e) {
        // En cas d'erreur d'enregistrement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'enregistrement du cours")),
        );
      }
    } else {
      // Si le formulaire est incomplet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
    }
  }

  // Création d'un champ de texte réutilisable
  Widget buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}), // Met à jour l'état quand on tape
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Titre de section stylisé
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  // Libération des ressources
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Interface utilisateur principale
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9DAFCB),
      appBar: AppBar(
        title: const Text('Ajouter un Cours'),
        backgroundColor: const Color(0xFF9DAFCB),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informations du Cours:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Section PDF
            sectionTitle("Fichier PDF"),
            ..._pdfs.map((pdf) => ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(pdf['title']),
              subtitle: Text(pdf['file'].path.split('/').last),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _pdfs.remove(pdf); // Supprime le fichier PDF
                  });
                },
              ),
            )),
            TextButton.icon(
              onPressed: _addPDF,
              icon: const Icon(Icons.attach_file, color: Colors.black),
              label: const Text(
                "Ajouter un fichier PDF",
                style: TextStyle(color: Colors.black),
              ),
            ),

            const SizedBox(height: 20),

            // Section Vidéos
            sectionTitle("Vidéos"),
            ..._videos.map((vid) => ListTile(
              leading: const Icon(Icons.video_library),
              title: Text(vid['title']),
              subtitle: Text(vid['file'].path.split('/').last),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _videos.remove(vid); // Supprime la vidéo
                  });
                },
              ),
            )),
            TextButton.icon(
              onPressed: _addVideo,
              icon: const Icon(Icons.video_call, color: Colors.black),
              label: const Text(
                "Ajouter une vidéo",
                style: TextStyle(color: Colors.black),
              ),
            ),

            // Champs du cours
            sectionTitle("Nom du Cours"),
            buildTextField("Nom du cours", _titleController),
            sectionTitle("Prix du Cours"),
            buildTextField("Prix", _priceController, isNumeric: true),

            // Catégorie (dropdown)
            sectionTitle("Catégorie"),
            FutureBuilder<List<String>>(
              future: _getCategories(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Erreur lors du chargement des catégories.");
                }
                final categories = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: categories
                      .map((cat) =>
                      DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Sélectionner une catégorie",
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),

            sectionTitle("Description du Cours"),
            buildTextField("Description", _descriptionController, maxLines: 10),

            const SizedBox(height: 20),

            // Bouton de soumission
            Center(
              child: ElevatedButton(
                onPressed: _isFormValid ? _saveCourse : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Ajouter le Cours",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
