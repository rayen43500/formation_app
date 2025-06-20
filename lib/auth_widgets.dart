import 'package:flutter/material.dart';

Widget buildTextField(String label, {bool obscure = false}) {
  return TextFormField(
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
    ),
  );
}
