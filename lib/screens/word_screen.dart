import 'package:flutter/material.dart';

class WordScreen extends StatelessWidget {
  const WordScreen({super.key});

  static const routeName = '/word';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Details')),
      body: const Center(child: Text('Word screen coming soon!')),
    );
  }
}
