import 'dart:math';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/song.dart';
import '../services/youtube_search_service.dart';
import '../widgets/song_picker.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final _search = YoutubeSearchService();
  Song? _selectedSong;
  late final _player = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showControls: true,
      showFullscreenButton: true,
    ),
  );
  bool _busy = false;
  bool _hasSong = false;
  String _message = 'Pick a song above. Selecting it will not start playback.';

  Future<void> _control(Future<void> Function() action, String message) async {
    setState(() => _busy = true);
    try {
      await action().timeout(const Duration(seconds: 15));
      if (mounted) setState(() => _message = message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'The player could not respond. Check your connection, then reopen this test.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _playSelectedSong() {
    final song = _selectedSong;
    if (song == null) return;
    setState(() => _hasSong = true);
    _control(
      () => _player.loadVideoById(videoId: song.videoId),
      'Playing ${song.title}. If playback is blocked, tap play in the video.',
    );
  }

  @override
  void dispose() {
    _search.close();
    _player.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your song')),
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
                    'Search YouTube inside the box and pick your song.',
                  ),
                  const SizedBox(height: 16),
                  SongPicker(
                    search: _search.search,
                    selectedId: _selectedSong?.videoId,
                    onSelected: (song) => setState(() => _selectedSong = song),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedSong case final song?) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text('Selected: ${song.title}\n${song.channel}'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'Playback test: play your selection here. The shared round timer will be added with the game phases.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _busy || _selectedSong == null
                            ? null
                            : _playSelectedSong,
                        child: Text(
                          _busy ? 'Please wait...' : 'Play selected song',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: !_hasSong || _busy
                            ? null
                            : () =>
                                  _control(_player.stopVideo, 'Song stopped.'),
                        child: const Text('Stop song'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Semantics(liveRegion: true, child: Text(_message)),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) => YoutubePlayer(
                      controller: _player,
                      aspectRatio:
                          constraints.maxWidth /
                          max(200, constraints.maxWidth * 9 / 16),
                    ),
                  ),
                  YoutubeValueBuilder(
                    controller: _player,
                    builder: (context, value) {
                      final message = switch (value.error) {
                        YoutubeError.none => null,
                        YoutubeError.videoNotFound ||
                        YoutubeError.cannotFindVideo =>
                          'This video is unavailable. Pick another song.',
                        YoutubeError.notEmbeddable ||
                        YoutubeError.sameAsNotEmbeddable ||
                        YoutubeError.sameAsNotEmbeddable2 => 'This video cannot play inside the app. Pick another song.',
                        YoutubeError.invalidParam =>
                          'YouTube rejected this video ID. Check the link.',
                        _ => 'YouTube could not start. Check your connection or player setup.',
                      };
                      return message == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(message),
                              ),
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
