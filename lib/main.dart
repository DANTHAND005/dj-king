import 'package:flutter/material.dart';

void main() {
  runApp(const DjKingApp());
}

class DjKingApp extends StatelessWidget {
  const DjKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'DJ King',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(child: Center(child: Text('DJ King'))),
      ),
    );
  }
}
