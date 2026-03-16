// lib/main_simple.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Simple',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('✅ App Funciona'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text(
            'Si ves esto, Flutter Web funciona correctamente',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}