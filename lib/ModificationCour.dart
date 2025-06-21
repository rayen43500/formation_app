import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ModificationCoursPage extends StatefulWidget {
  final DocumentSnapshot cours;

  const ModificationCoursPage({Key? key, required this.cours}) : super(key: key);

  @override
  _ModificationCoursPageState createState() => _ModificationCoursPageState();
}

class _ModificationCoursPageState extends State<ModificationCoursPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late TextEditingController _prixController;

  List<Map<String, String>> videos = [];
  List<Map<String, String>> pdfs = [];
  List<String> notes = [];

  @override
  void initState() {
    super.initState();

    _titreController = TextEditingController(text: widget.cours['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.cours['description'] ?? '');
    _prixController = TextEditingController(text: widget.cours['price']?.toString() ?? '');

    if (widget.cours.data().toString().contains('videos')) {
      final List<dynamic> rawVideos = widget.cours['videos'] ?? [];
      videos = rawVideos.map<Map<String, String>>((item) {
        return {
          'title': item['title']?.toString() ?? '',
          'url': item['url']?.toString() ?? '',
        };
      }).toList();
    }

    if (widget.cours.data().toString().contains('pdfs')) {
      final List<dynamic> rawPdfs = widget.cours['pdfs'] ?? [];
      pdfs = rawPdfs.map<Map<String, String>>((item) {
        return {
          'title': item['title']?.toString() ?? '',
          'url': item['url']?.toString() ?? '',
        };
      }).toList();
    }

    if (widget.cours.data().toString().contains('notes')) {
      notes = List<String>.from(widget.cours['notes'] ?? []);
    }
  }

  Future<String?> _uploadToCloudinary(File file, String folder, String fileType) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/deltanzkn/upload');
    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = 'skillbridge';
    request.fields['folder'] = folder;

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final jsonResp = json.decode(respStr);
      return jsonResp['secure_url'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'upload $fileType')));
      return null;
    }
  }

  Future<void> _updateFieldInFirestore(String field, List<Map<String, String>> list) async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.cours.id)
        .update({field: list});
  }

  Future<void> _updateNotes() async {
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.cours.id)
        .update({'notes': notes});
  }

  Future<void> _addFileWithTitle(String folder, String fileType, List<Map<String, String>> list, String field) async {
    final params = OpenFileDialogParams(
      dialogType: OpenFileDialogType.document,
      fileExtensionsFilter: fileType == 'video' ? ['mp4', 'mov', 'avi'] : ['pdf'],
    );

    final filePath = await FlutterFileDialog.pickFile(params: params);

    if (filePath != null) {
      final file = File(filePath);
      final downloadUrl = await _uploadToCloudinary(file, folder, fileType);

      if (downloadUrl != null) {
        String? title;
        final controller = TextEditingController();
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Titre du ${fileType.toUpperCase()}'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Entrez un titre'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  title = controller.text.trim();
                  Navigator.pop(context);
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
        );

        if (title != null && title!.isNotEmpty) {
          setState(() {
            list.add({'title': title!, 'url': downloadUrl});
          });
          await _updateFieldInFirestore(field, list);
        }
      }
    }
  }

  Future<void> _editFileTitle(List<Map<String, String>> list, int index, String field) async {
    final controller = TextEditingController(text: list[index]['title']);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le titre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Titre du fichier'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  list[index]['title'] = controller.text.trim();
                });
                _updateFieldInFirestore(field, list);
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(int index) async {
    final controller = TextEditingController(text: notes[index]);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Contenu de la note'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final updated = controller.text.trim();
              if (updated.isNotEmpty) {
                setState(() {
                  notes[index] = updated;
                });
                _updateNotes();
              }
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _removeFileWithTitle(List<Map<String, String>> list, int index, String field) {
    setState(() {
      list.removeAt(index);
    });
    _updateFieldInFirestore(field, list);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9FB0CC),
      appBar: AppBar(
        title: const Text('Modifier Cours'),
        backgroundColor: const Color(0xFF9FB0CC),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titreController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez saisir un titre' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Veuillez saisir une description' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _prixController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Veuillez saisir un prix' : null,
              ),
              const SizedBox(height: 20),
              _buildFileList('Vidéos', videos, 'video', 'videos', 'videos'),
              _buildFileList('PDFs', pdfs, 'pdf', 'pdfs', 'pdfs'),
              const SizedBox(height: 20),
              Text('Notes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...notes.asMap().entries.map((entry) {
                final index = entry.key;
                final note = entry.value;
                return Row(
                  children: [
                    Expanded(child: Text('• $note')),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black45),
                      onPressed: () => _editNote(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          notes.removeAt(index);
                        });
                        _updateNotes();
                      },
                    ),
                  ],
                );
              }).toList(),
              ElevatedButton.icon(
                onPressed: () async {
                  final controller = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Ajouter une note'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'Contenu de la note'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                        ElevatedButton(
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isNotEmpty) {
                              setState(() {
                                notes.add(text);
                              });
                              _updateNotes();
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white60,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirebaseFirestore.instance.collection('courses').doc(widget.cours.id).update({
                      'title': _titreController.text,
                      'description': _descriptionController.text,
                      'price': double.tryParse(_prixController.text) ?? 0,
                      'videos': videos,
                      'pdfs': pdfs,
                      'notes': notes,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cours mis à jour avec succès')),
                    );
                    Navigator.pop(context);
                  }
                },

                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileList(String label, List<Map<String, String>> files, String fileType, String folder, String field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white60,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              onPressed: () => _addFileWithTitle(folder, fileType, files, field),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          const Text('Aucun fichier', style: TextStyle(color: Colors.black38)),
        ...files.asMap().entries.map((entry) {
          int index = entry.key;
          final title = entry.value['title'] ?? '';
          return Row(
            children: [
              Expanded(child: Text('• $title')),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black38),
                onPressed: () => _editFileTitle(files, index, field),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Color(0xFFAF8E89)),
                onPressed: () => _removeFileWithTitle(files, index, field),
              ),
            ],
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }
}
