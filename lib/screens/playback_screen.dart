import 'dart:math';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../utils/youtube_link.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _link = TextEditingController();
  late final _player = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showControls: true,
      showFullscreenButton: true,
    ),
  );
  bool _busy = false;
  bool _hasSong = false;
  String _message = 'Paste a YouTube link to test a song.';

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

  void _loadSong() {
    if (!_formKey.currentState!.validate()) return;
    final videoId = youtubeVideoId(_link.text)!;
    setState(() => _hasSong = true);
    _control(
      () => _player.cueVideoById(videoId: videoId),
      'Song loaded. Tap play in the video.',
    );
  }

  @override
  void dispose() {
    _link.dispose();
    _player.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Song playback test')),
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
                    'Load a song, play it, stop it, then load a second song. Audio plays on this device.',
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _link,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'YouTube link',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => youtubeVideoId(value ?? '') == null
                          ? 'Paste a valid HTTPS YouTube video link.'
                          : null,
                      onFieldSubmitted: (_) {
                        if (!_busy) _loadSong();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _busy ? null : _loadSong,
                        child: Text(_busy ? 'Please wait...' : 'Load song'),
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
