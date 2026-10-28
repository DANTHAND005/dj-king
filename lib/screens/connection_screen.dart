import 'package:flutter/material.dart';

import '../services/game_service.dart';
import 'home_screen.dart';

/// Signs the player in, then shows the front page.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key, required this.signIn, required this.game});

  final Future<String> Function() signIn;
  final GameService game;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late Future<String> _connection;

  @override
  void initState() {
    super.initState();
    _connection = widget.signIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _connection,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return HomeScreen(game: widget.game);
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Could not connect. Check your internet and try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {
                            _connection = widget.signIn();
                          }),
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connecting...'),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
