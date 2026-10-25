import 'package:flutter/material.dart';

import 'playback_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key, required this.signIn});

  final Future<String> Function() signIn;

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
    return Scaffold(
      appBar: AppBar(title: const Text('DJ King')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: FutureBuilder<String>(
                future: _connection,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Connecting your player...'),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Could not connect. Check your internet and try again.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {
                            _connection = widget.signIn();
                          }),
                          child: const Text('Try again'),
                        ),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your player is connected',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      const Text('Your player ID'),
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Player ID: ${snapshot.requireData}',
                        excludeSemantics: true,
                        child: SelectableText(snapshot.requireData),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Stage 1: check that each phone shows a different ID, then test song playback.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PlaybackScreen(),
                          ),
                        ),
                        child: const Text('Test song playback'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
