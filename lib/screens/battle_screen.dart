import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/battle_order.dart';
import '../models/song.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.left, required this.right});

  final Song left;
  final Song right;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final BattleOrder _order;
  late final YoutubePlayerController _player;
  late final StreamSubscription<YoutubePlayerValue> _events;
  bool _changingSong = false;
  bool _started = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = BattleOrder(left: widget.left, right: widget.right);
    _player = YoutubePlayerController.fromVideoId(
      videoId: widget.left.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
    _events = _player.listen(_onPlayback);
  }

  void _onPlayback(YoutubePlayerValue value) {
    if (!mounted || _order.finished || _changingSong) return;
    if (value.hasError) {
      final message = switch (value.error) {
        YoutubeError.videoNotFound || YoutubeError.cannotFindVideo =>
          'This video is unavailable. Retry or skip it.',
        YoutubeError.notEmbeddable ||
        YoutubeError.sameAsNotEmbeddable ||
        YoutubeError.sameAsNotEmbeddable2 =>
          'This video cannot play inside the app. Retry or skip it.',
        YoutubeError.invalidParam =>
          'YouTube rejected this video ID. Retry or skip it.',
        _ =>
          'YouTube could not start. Check your connection or retry the song.',
      };
      if (_error != message) setState(() => _error = message);
      return;
    }
    if (value.playerState == PlayerState.playing &&
        value.metaData.videoId == _order.currentSong!.videoId) {
      if (!_started || _error != null) {
        setState(() {
          _started = true;
          _error = null;
        });
      }
    } else if (value.playerState == PlayerState.ended && _started) {
      _advance();
    }
  }

  Future<void> _advance() async {
    if (_changingSong || _order.finished) return;
    setState(() {
      _changingSong = true;
      _started = false;
      _error = null;
    });
    try {
      await _player.stopVideo().timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(_order.advance);
      if (_order.currentSong case final song?) {
        await _player
            .loadVideoById(videoId: song.videoId)
            .timeout(const Duration(seconds: 15));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'The player did not respond. Retry the current song.',
        );
      }
    } finally {
      if (mounted) setState(() => _changingSong = false);
    }
  }

  Future<void> _retry() async {
    final song = _order.currentSong;
    if (song == null || _changingSong) return;
    setState(() {
      _changingSong = true;
      _started = false;
      _error = null;
    });
    try {
      await _player
          .loadVideoById(videoId: song.videoId)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'The player did not respond. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _changingSong = false);
    }
  }

  @override
  void dispose() {
    _events.cancel();
    _player.close();
    super.dispose();
  }

  Widget _songPanel(String side, Song song, int position) {
    final active = !_order.finished && _order.position == position;
    var status = 'Up next';
    if (_order.position > position) {
      status = 'Finished';
    } else if (active) {
      status = _started ? 'Now playing' : 'Ready to play';
    }
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$side contestant',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(song.title, maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Semantics(liveRegion: true, child: Text(status)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var buttonLabel = 'End right song';
    if (_changingSong) {
      buttonLabel = 'Switching songs...';
    } else if (_error != null) {
      buttonLabel = 'Skip unavailable song';
    } else if (_order.position == 0) {
      buttonLabel = 'End left song and play right';
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Song battle')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Left first, then right. Only one song plays at a time.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _songPanel('Left', widget.left, 0),
                      const SizedBox(width: 12),
                      _songPanel('Right', widget.right, 1),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_order.finished) ...[
                    const Text('Both songs are finished.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to start'),
                    ),
                  ] else ...[
                    const Text('If playback waits, tap Play in the video.'),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) => YoutubePlayer(
                        controller: _player,
                        aspectRatio:
                            constraints.maxWidth /
                            max(200, constraints.maxWidth * 9 / 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error case final message?) ...[
                      Semantics(liveRegion: true, child: Text(message)),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed:
                              _changingSong || (!_started && _error == null)
                              ? null
                              : _advance,
                          child: Text(buttonLabel),
                        ),
                        if (_error != null)
                          OutlinedButton(
                            onPressed: _changingSong ? null : _retry,
                            child: const Text('Retry song'),
                          ),
                      ],
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
