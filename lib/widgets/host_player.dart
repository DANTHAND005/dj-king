import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/room.dart';
import '../models/song.dart';
import '../services/game_service.dart';
import '../utils/run_action.dart';

/// Host only: plays the current song, ends on video end or a contestant's stop request.
class HostPlayer extends StatefulWidget {
  const HostPlayer({
    super.key,
    required this.game,
    required this.room,
    required this.song,
  });

  final GameService game;
  final Room room;
  final Song song;

  @override
  State<HostPlayer> createState() => _HostPlayerState();
}

class _HostPlayerState extends State<HostPlayer> {
  late final YoutubePlayerController _player =
      YoutubePlayerController.fromVideoId(
        videoId: widget.song.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      );
  late final StreamSubscription<YoutubePlayerValue> _events;
  late final StreamSubscription<bool> _stops;
  bool _advancing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _events = _player.listen(_onPlayback);
    _stops = widget.game.watchStop(widget.room).listen((stop) {
      if (stop) _next();
    });
  }

  void _onPlayback(YoutubePlayerValue value) {
    if (!mounted) return;
    if (value.hasError) {
      if (_error == null) {
        setState(
          () => _error =
              'This video cannot play. Skip it or ask for another song.',
        );
      }
    } else if (value.playerState == PlayerState.ended) {
      _next();
    }
  }

  Future<void> _next() async {
    if (_advancing) return;
    _advancing = true;
    await runAction(context, () => widget.game.advancePlayback(widget.room));
    _advancing = false;
  }

  @override
  void dispose() {
    _events.cancel();
    _stops.cancel();
    _player.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final contestant = room.activeContestant!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${room.nameOf(contestant)}: ${widget.song.title}'),
        Text(widget.song.channel),
        const SizedBox(height: 8),
        YoutubePlayer(controller: _player, aspectRatio: 16 / 9),
        const SizedBox(height: 8),
        if (_error case final message?)
          Semantics(liveRegion: true, child: Text(message)),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(onPressed: _next, child: const Text('Skip song')),
            if (_error != null)
              OutlinedButton(
                onPressed: () => runAction(
                  context,
                  () => widget.game.replaceSong(room, contestant),
                ),
                child: Text('Ask ${room.nameOf(contestant)} for another song'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('If playback waits, tap Play in the video.'),
      ],
    );
  }
}
