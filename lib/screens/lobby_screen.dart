import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/room.dart';
import '../services/game_service.dart';
import '../utils/run_action.dart';
import '../widgets/animations.dart';
import '../widgets/pick_dialogs.dart';
import 'game_view.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.game, required this.code});

  final GameService game;
  final String code;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late final Stream<Room?> _stream = widget.game.watchRoom(widget.code);
  Room? _latest;

  // Players just leave. The host has to confirm, because leaving ends the game for everyone.
  Future<void> _leave(bool didPop) async {
    final room = _latest;
    if (!didPop && room != null) {
      final end = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('End the game?'),
          content: const Text('This closes the room for everyone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Keep playing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('End game'),
            ),
          ],
        ),
      );
      if (end != true) return;
    }
    if (room != null) {
      try {
        await widget.game.leaveRoom(room);
      } catch (_) {
        // leaving is best effort; the disconnect handler marks us offline anyway.
      }
    }
    if (!didPop && mounted) Navigator.of(context).pop();
  }

  Widget _lobby(Room room) {
    final theme = Theme.of(context).textTheme;
    final isHost = room.hostId == widget.game.uid;
    final ready = room.connectedPlayers.length >= 3;
    return Column(
      key: const ValueKey('lobby'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Join with this code',
          textAlign: TextAlign.center,
          style: theme.titleMedium,
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: room.code));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Code copied')));
          },
          child: Text(
            room.code,
            textAlign: TextAlign.center,
            style: theme.displayLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
        ),
        Text(
          'Host: ${room.hostName}${room.hostOnline ? '' : ' (offline)'}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Players: ${room.connectedPlayers.length}',
          style: theme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (room.players.isEmpty)
          const Text(
            'Waiting for players to join.',
            textAlign: TextAlign.center,
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final player in room.players.values)
              Chip(
                avatar: Icon(
                  Icons.circle,
                  size: 12,
                  color: player.connected ? Colors.greenAccent : Colors.grey,
                ),
                label: Text(
                  player.id == widget.game.uid
                      ? '${player.nickname} (you)'
                      : player.nickname,
                ),
              ),
          ],
        ),
        if (isHost && !room.players.keys.any(widget.game.isBot)) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                runAction(context, () => widget.game.addBots(room)),
            child: const Text('Add test players'),
          ),
        ],
        if (isHost) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final all = room.genres.length == gameGenres.length;
              final picked = await pickGenres(context, all ? [] : room.genres);
              if (picked != null && mounted) {
                runAction(context, () => widget.game.setGenres(room, picked));
              }
            },
            child: Text(
              room.genres.length == gameGenres.length
                  ? 'Genres: random from all ${gameGenres.length}'
                  : 'Genres: your ${room.genres.length} picks',
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (isHost && ready)
          FilledButton(
            onPressed: () =>
                runAction(context, () => widget.game.nextRound(room)),
            child: const Text('Start the game'),
          )
        else
          Text(
            !ready
                ? 'At least three players are needed to start.'
                : 'Waiting for the host to start.',
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _content(AsyncSnapshot<Room?> snapshot) {
    if (snapshot.hasError) {
      return const Text(
        'Lost the connection to this room. Go back and join again.',
      );
    }
    if (!snapshot.hasData &&
        snapshot.connectionState != ConnectionState.active) {
      return const CircularProgressIndicator();
    }
    final room = snapshot.data;
    if (room == null) return const Text('This room no longer exists.');
    if (room.phase == GamePhase.closed) {
      return const Text('The host ended this room.');
    }
    if (room.phase == GamePhase.lobby) return _lobby(room);
    return GameView(
      key: const ValueKey('game'),
      game: widget.game,
      room: room,
      uid: widget.game.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Room?>(
      stream: _stream,
      builder: (context, snapshot) {
        final room = _latest = snapshot.data ?? _latest;
        final hostIsPlaying =
            room != null &&
            room.hostId == widget.game.uid &&
            room.phase != GamePhase.closed;
        return PopScope(
          canPop: !hostIsPlaying,
          onPopInvokedWithResult: (didPop, _) => _leave(didPop),
          child: Scaffold(
            appBar: AppBar(title: const Text('DJ King')),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: slideFade,
                      child: _content(snapshot),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
