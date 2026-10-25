import 'package:flutter/material.dart';

import 'screens/connection_screen.dart';

class DjKingApp extends StatelessWidget {
  const DjKingApp({super.key, required this.signIn});

  final Future<String> Function() signIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ King',
      debugShowCheckedModeBanner: false,
      home: ConnectionScreen(signIn: signIn),
    );
  }
}
