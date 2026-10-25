import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/youtube_search_service.dart';
import '../widgets/battle_countdown.dart';
import '../widgets/song_picker.dart';
import 'battle_screen.dart';

class SongSelectionScreen extends StatefulWidget {
  const SongSelectionScreen({super.key});

  @override
  State<SongSelectionScreen> createState() => _SongSelectionScreenState();
}

class _SongSelectionScreenState extends State<SongSelectionScreen> {
  final _search = YoutubeSearchService();
  Song? _left;
  Song? _right;

  @override
  void dispose() {
    _search.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose the battle songs')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Local battle preview: choose both contestants’ songs on this device. Multiplayer joining is not connected yet.',
                  ),
                  const SizedBox(height: 16),
                  if (_left == null || _right == null) ...[
                    Text(
                      _left == null
                          ? 'Left contestant: pick a song'
                          : 'Right contestant: pick a song',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SongPicker(
                      search: _search.search,
                      onSelected: (song) => setState(() {
                        if (_left == null) {
                          _left = song;
                        } else {
                          _right = song;
                        }
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_left case final song?) Text('Left song: ${song.title}'),
                  if (_right case final song?) ...[
                    const SizedBox(height: 8),
                    Text('Right song: ${song.title}'),
                    const SizedBox(height: 24),
                    BattleCountdown(
                      onFinished: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BattleScreen(left: _left!, right: _right!),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
