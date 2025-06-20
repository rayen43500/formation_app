import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailCoursAdmin extends StatefulWidget {
  final String courseId;

  DetailCoursAdmin({required this.courseId});

  @override
  _DetailCoursAdminState createState() => _DetailCoursAdminState();
}

class _DetailCoursAdminState extends State<DetailCoursAdmin> {
  Widget _buildVideoList(List videos) {
    if (videos.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vidéos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...videos.map((video) {
          final title = video['title'] ?? 'Sans titre';
          final url = video['url'] ?? '';
          return ListTile(
            leading: Icon(Icons.play_circle_fill, color: Colors.blue),
            title: Text(title),
            subtitle: Text(url, style: TextStyle(fontSize: 12)),
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Impossible d'ouvrir la vidéo.")),
                );
              }
            },
          );
        }).toList(),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPdfList(List pdfs) {
    if (pdfs.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documents PDF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...pdfs.map((pdf) {
          final title = pdf['title'] ?? 'Sans titre';
          final url = pdf['url'] ?? '';
          return ListTile(
            leading: Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(title),
            subtitle: Text(url, style: TextStyle(fontSize: 12)),
            onTap: () async {
              final uri = Uri.parse(url.trim());
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Impossible d'ouvrir ce PDF.")),
                );
              }
            },
          );
        }).toList(),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseDocRef =
    FirebaseFirestore.instance.collection('courses').doc(widget.courseId);

    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB), // ✅ Couleur de fond ajoutée
      appBar: AppBar(
        backgroundColor: Color(0xFF9DAFCB),
        title: Text('Détail du cours'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: courseDocRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Erreur: ${snapshot.error}"));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final courseData = snapshot.data!.data() as Map<String, dynamic>?;

          if (courseData == null) return Center(child: Text("Cours introuvable"));

          final videos = (courseData['videos'] is List)
              ? List<Map<String, dynamic>>.from(courseData['videos'])
              : <Map<String, dynamic>>[];

          final pdfs = (courseData['pdfs'] is List)
              ? List<Map<String, dynamic>>.from(courseData['pdfs'])
              : <Map<String, dynamic>>[];

          return Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Titre : ${courseData['title']}", style: TextStyle(fontSize: 20)),
                  SizedBox(height: 8),
                  Text("Description : ${courseData['description']}", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Catégorie : ${courseData['category']}", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Prix : ${courseData['price']} TND", style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  _buildVideoList(videos),
                  _buildPdfList(pdfs),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
