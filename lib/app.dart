import 'package:flutter/material.dart';

import 'screens/connection_screen.dart';
import 'services/game_service.dart';
import 'widgets/backdrop.dart';

const _navy = Color(0xFF14246B);
const _yellow = Color(0xFFFFC93C);

class DjKingApp extends StatelessWidget {
  const DjKingApp({super.key, required this.signIn, required this.game});

  final Future<String> Function() signIn;
  final GameService game;

  @override
  Widget build(BuildContext context) {
    final button = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const label = TextStyle(fontFamily: 'Lilita', fontSize: 20);
    return MaterialApp(
      title: 'DJ King',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: Typography.material2021().white.apply(fontFamily: 'Lilita'),
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _navy,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor:
            Colors.transparent, // the red and blue Backdrop shows through
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _yellow,
            foregroundColor: Colors.black,
            side: const BorderSide(width: 3),
            minimumSize: const Size.fromHeight(52),
            textStyle: label,
            shape: button,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 2),
            minimumSize: const Size.fromHeight(52),
            textStyle: label,
            shape: button,
          ),
        ),
      ),
      // Bigger text everywhere so it is easy to read from across a room.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.2,
        maxScaleFactor: 1.2,
        child: Backdrop(child: child!),
      ),
      home: ConnectionScreen(signIn: signIn, game: game),
    );
  }
}
