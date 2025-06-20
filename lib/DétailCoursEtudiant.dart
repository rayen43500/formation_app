import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DetailCoursEtudiant extends StatefulWidget {
  final String courseId;

  DetailCoursEtudiant({required this.courseId});

  @override
  _DetailCoursPageState createState() => _DetailCoursPageState();
}

class _DetailCoursPageState extends State<DetailCoursEtudiant> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingComment = false;

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception("Permission refusée");
      }

      final dir = await getExternalStorageDirectory();
      final path = '${dir!.path}/$fileName';

      final dio = Dio();
      await dio.download(url, path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fichier téléchargé : $fileName")),
      );
    } catch (e) {
      print("Erreur téléchargement : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec du téléchargement")),
      );
    }
  }

  Future<void> _addComment(String commentText) async {
    if (commentText.trim().isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('purchases')
          .where('courseIdOriginal', isEqualTo: widget.courseId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (query.docs.isNotEmpty) {
        final docRef = query.docs.first.reference;

        final comment = {
          'text': commentText.trim(),
          'createdAt': Timestamp.now(),
        };

        await docRef.update({
          'commentaire': FieldValue.arrayUnion([comment])
        });

        _commentController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Achat non trouvé. Vous devez acheter le cours pour commenter.")),
        );
      }
    } catch (e) {
      print("Erreur ajout commentaire : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'ajout du commentaire")),
      );
    } finally {
      setState(() {
        _isAddingComment = false;
      });
    }
  }

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
            trailing: IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _downloadFile(url, "$title.mp4"),
            ),
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
            trailing: IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _downloadFile(url, "$title.pdf"),
            ),
            onTap: () async {
              final uri = Uri.parse(url);
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

  Widget _buildCommentsList(List commentaires, DocumentReference docRef) {
    if (commentaires.isEmpty) return Text("Aucun commentaire.");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commentaires', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        ...commentaires.map<Widget>((comment) {
          final text = comment['text'] ?? '';
          final timestamp = comment['createdAt'];
          final dateStr = (timestamp is Timestamp)
              ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
              : '';

          return ListTile(
            leading: Icon(Icons.comment),
            title: Text(text),
            subtitle: Text(dateStr),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                List commentairesList = List.from(commentaires);
                int index = commentairesList.indexWhere((c) => c == comment);
                if (index == -1) return;

                if (value == 'edit') {
                  final newCommentText = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(text: text);
                      return AlertDialog(
                        title: Text("Modifier le commentaire"),
                        content: TextField(
                          controller: controller,
                          maxLines: 3,
                          decoration: InputDecoration(border: OutlineInputBorder()),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
                          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text("Enregistrer")),
                        ],
                      );
                    },
                  );

                  if (newCommentText != null && newCommentText.isNotEmpty && newCommentText != text) {
                    commentairesList[index] = {
                      'text': newCommentText,
                      'createdAt': Timestamp.now(),
                    };
                    await docRef.update({'commentaire': commentairesList});
                  }
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Supprimer le commentaire"),
                      content: Text("Voulez-vous vraiment supprimer ce commentaire ?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Annuler")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Supprimer")),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    commentairesList.removeAt(index);
                    await docRef.update({'commentaire': commentairesList});
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
          );
        }),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text("Utilisateur non connecté")));

    return Scaffold(
      backgroundColor: Color(0xFF9DAFCB),
      appBar: AppBar(
        backgroundColor: Color(0xFF9DAFCB),
        title: Text('Détail du cours'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('purchases')
            .where('courseIdOriginal', isEqualTo: widget.courseId)
            .where('userId', isEqualTo: user.uid)
            .get(),
        builder: (context, purchaseSnapshot) {
          if (purchaseSnapshot.hasError) return Center(child: Text("Erreur: ${purchaseSnapshot.error}"));
          if (!purchaseSnapshot.hasData) return Center(child: CircularProgressIndicator());

          if (purchaseSnapshot.data!.docs.isEmpty) return Center(child: Text("Cours non acheté"));

          final purchaseDoc = purchaseSnapshot.data!.docs.first;
          final courseIdOriginal = purchaseDoc['courseIdOriginal'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('courses').doc(courseIdOriginal).get(),
            builder: (context, courseSnapshot) {
              if (courseSnapshot.hasError) return Center(child: Text("Erreur: ${courseSnapshot.error}"));
              if (!courseSnapshot.hasData) return Center(child: CircularProgressIndicator());

              if (!courseSnapshot.data!.exists) return Center(child: Text("Cours non trouvé"));

              final courseData = courseSnapshot.data!.data() as Map<String, dynamic>;

              final videos = (courseData['videos'] is List)
                  ? List<Map<String, dynamic>>.from(courseData['videos'])
                  : <Map<String, dynamic>>[];

              final pdfs = (courseData['pdfs'] is List)
                  ? List<Map<String, dynamic>>.from(courseData['pdfs'])
                  : <Map<String, dynamic>>[];

              final commentaires = (purchaseDoc['commentaire'] is List)
                  ? purchaseDoc['commentaire'].map((e) {
                if (e is String) {
                  return {'text': e, 'createdAt': Timestamp(0, 0)};
                } else if (e is Map<String, dynamic>) {
                  return e;
                } else {
                  return {'text': e.toString(), 'createdAt': Timestamp(0, 0)};
                }
              }).toList()
                  : <Map<String, dynamic>>[];

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVideoList(videos),
                            _buildPdfList(pdfs),
                            _buildCommentsList(commentaires, purchaseDoc.reference),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: 'Ajouter un commentaire',
                              border: OutlineInputBorder(),
                            ),
                            minLines: 1,
                            maxLines: 3,
                          ),
                        ),
                        SizedBox(width: 8),
                        _isAddingComment
                            ? CircularProgressIndicator()
                            : IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () => _addComment(_commentController.text),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
