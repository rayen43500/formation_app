import 'package:flutter/material.dart';

class GestadminC extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Statistiques et Commentaires"),
      ),
      body: Center(
        child: Text(
          "Page des statistiques, commentaires et notes",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
