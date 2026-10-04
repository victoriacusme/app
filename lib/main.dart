import 'package:flutter/material.dart';

void main() {
  runApp(const NexoBankApp());
}

class NexoBankApp extends StatelessWidget {
  const NexoBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexo Bank',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B5FFF)),
      ),
      home: const Scaffold(
        body: Center(child: Text('Nexo Bank')),
      ),
    );
  }
}
