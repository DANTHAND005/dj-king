import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/room.dart';
import '../models/song.dart';
import '../services/game_service.dart';
import '../services/youtube_search_service.dart';
import '../utils/run_action.dart';
import '../widgets/animations.dart';
import '../widgets/backdrop.dart';
import '../widgets/clock.dart';
import '../widgets/confetti.dart';
import '../widgets/host_player.dart';
import '../widgets/pick_dialogs.dart';
import '../widgets/song_picker.dart';
import '../widgets/spin_wheel.dart';

/// One block per room phase. The host's copy also drives the timed phase changes.
class GameView extends StatefulWidget {
  const GameView({
    super.key,
    required this.game,
    required this.room,
    required this.uid,
  });

  final GameService game;
  final Room room;
  final String uid;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  final _search = YoutubeSearchService();
  Timer? _tick;
  bool _working = false;
  Song? _mySong;
  bool _voted = false;

  Room get room => widget.room;
  bool get isHost => room.hostId == widget.uid;
  bool get isContestant =>
      widget.uid == room.leftId || widget.uid == room.rightId;
  bool get isPlaying =>
      room.phase == GamePhase.songA || room.phase == GamePhase.songB;
  String _who(String? id) => id == null ? '?' : room.nameOf(id);

  // The playing song's cover becomes the app background. Set after the frame, never during build.
  void _syncCover() {
    final url = isPlaying
        ? room.songs[room.activeContestant]?.thumbnailUrl
        : null;
    WidgetsBinding.instance.addPostFrameCallback((_) => coverArt.value = url);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => gameOn.value = true);
    _syncCover();
    if (isHost) {
      WakelockPlus.enable().catchError((_) {});
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _drive());
    }
  }

  @override
  void didUpdateWidget(GameView old) {
    super.didUpdateWidget(old);
    _syncCover();
    if (old.room.phase == room.phase) return;
    final result = room.results[room.roundKey];
    if (room.phase == GamePhase.result &&
            result != null &&
            result.winnerId != 'draw' ||
        room.phase == GamePhase.finished && room.leaders.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => celebrate.value++);
    }
    // A replacement restart also lands here, so the other contestant sees the picker again.
    if (room.phase == GamePhase.submission) _mySong = null;
    if (room.phase == GamePhase.voting) _voted = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      coverArt.value = null;
      gameOn.value = false;
    });
    _tick?.cancel();
    _search.close();
    if (isHost) WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  // Host only: advance phases that end on a deadline or when everyone has answered.
  Future<void> _drive() async {
    if (_working) return;
    _working = true;
    final current = room;
    try {
      await widget.game.playBots(current);
      switch (current.phase) {
        case GamePhase.submission:
          await widget.game.finishSubmission(current);
        case GamePhase.countdown:
          if (widget.game.now >= (current.deadline ?? 0)) {
            await widget.game.advancePlayback(current);
          }
        case GamePhase.voting:
          await widget.game.finishVoting(current);
        default:
      }
    } catch (_) {
      // ponytail: "still open" and stale-revision errors are expected; the next tick retries.
    } finally {
      _working = false;
    }
  }

  Widget _hostButton(String label, Future<void> Function() action) =>
      FilledButton(
        onPressed: () => runAction(context, action),
        child: Text(label),
      );

  Future<void> _submit(Song song) => runAction(context, () async {
    await widget.game.submitSong(room, song);
    if (mounted) setState(() => _mySong = song);
  });

  Future<void> _vote(String contestant) => runAction(context, () async {
    await widget.game.vote(room, contestant);
    if (mounted) setState(() => _voted = true);
  });

  /// Host replaces the left or right contestant with another connected player.
  Future<void> _swap() async {
    final sides = [
      if (room.leftId != null) true,
      if (room.rightId != null) false,
    ];
    final left = sides.length == 1
        ? true
        : await choose<bool>(context, 'Replace which contestant?', [
            (true, 'Left: ${_who(room.leftId)}'),
            (false, 'Right: ${_who(room.rightId)}'),
          ]);
    if (left == null || !mounted) return;
    final options = [
      for (final p in room.connectedPlayers)
        if (p.id != room.leftId && p.id != room.rightId) (p.id, p.nickname),
    ];
    if (options.isEmpty) {
      return runAction(context, () async {
        throw const GameException('Nobody else is available to swap in.');
      });
    }
    final id = await choose<String>(context, 'Swap in', options);
    if (id == null || !mounted) return;
    await runAction(context, () => widget.game.setContestant(room, left, id));
  }

  Widget _scoreboard() {
    // Only the two contestants can score.
    final entries =
        room.scores.entries
            .where(
              (entry) => entry.key == room.leftId || entry.key == room.rightId,
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        for (final entry in entries)
          ListTile(
            dense: true,
            title: Text(room.nameOf(entry.key)),
            trailing: Text('${entry.value}'),
          ),
      ],
    );
  }

  List<Widget> _phase() {
    final left = room.leftId, right = room.rightId;
    final big = Theme.of(context).textTheme.headlineMedium;
    switch (room.phase) {
      case GamePhase.contestants:
        // The second wheel leaves out the first contestant, who can't be picked twice.
        final players = [
          for (final p in room.connectedPlayers)
            if (right == null || p.id != left) p,
        ]..sort((a, b) => a.id.compareTo(b.id));
        final picked = players.indexWhere((p) => p.id == (right ?? left));
        return [
          SpinWheel(
            key: ValueKey(right == null ? 'first' : 'second'),
            labels: [for (final p in players) p.nickname],
            target: picked < 0 ? null : picked,
          ),
          const SizedBox(height: 16),
          if (!isHost)
            const Text(
              'The host is picking the contestants.',
              textAlign: TextAlign.center,
            )
          else if (right == null)
            _hostButton(
              'Spin for the ${left == null ? 'left' : 'right'} contestant',
              () => widget.game.spinContestant(room),
            )
          else
            _hostButton('Pick the genre', () => widget.game.openGenre(room)),

          if (isHost && left != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _swap,
              child: const Text('Swap a contestant'),
            ),
          ],
        ];
      case GamePhase.genre:
        final genre = room.genre;
        return [
          SpinWheel(
            key: const ValueKey('genres'),
            labels: room.genres,
            target: genre == null ? null : room.genres.indexOf(genre),
          ),
          const SizedBox(height: 16),
          if (!isHost)
            Text(
              genre == null
                  ? 'The host is choosing the genre.'
                  : 'Get ready to pick a song.',
              textAlign: TextAlign.center,
            )
          else if (genre == null)
            _hostButton(
              'Spin the genre wheel',
              () => widget.game.spinGenre(room),
            )
          else
            _hostButton(
              'Open song selection',
              () => widget.game.openSubmission(room),
            ),
        ];
      case GamePhase.submission:
        return [
          Clock(game: widget.game, deadline: room.deadline, label: 'Time left'),
          if (room.notice case final notice?) Text(notice),
          const SizedBox(height: 12),
          if (!isContestant)
            Text(
              '${_who(left)} and ${_who(right)} are choosing a ${room.genre} song.',
            )
          else if (_mySong case final song?) ...[
            Text('Locked in: ${song.title}'),
            TextButton(
              onPressed: () => setState(() => _mySong = null),
              child: const Text('Pick a different song'),
            ),
          ] else ...[
            Text('Pick a ${room.genre} song'),
            const SizedBox(height: 8),
            SongPicker(search: _search.search, onSelected: _submit),
          ],
        ];
      case GamePhase.countdown:
        return [
          Clock(
            game: widget.game,
            deadline: room.deadline,
            label: 'Battle starts in',
          ),
        ];
      case GamePhase.songA:
      case GamePhase.songB:
        final playing = room.activeContestant!;
        final song = room.songs[playing];
        if (song == null) return [const Text('Waiting for the song.')];
        if (isHost) {
          return [HostPlayer(game: widget.game, room: room, song: song)];
        }
        return [
          const Text('Now playing on the host phone.'),
          Text('${room.nameOf(playing)}: ${song.title}'),
          if (widget.uid == playing) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  runAction(context, () => widget.game.requestStop(room)),
              child: const Text('Stop my song'),
            ),
          ],
        ];
      case GamePhase.voting:
        final voter = room.voters.contains(widget.uid);
        return [
          Clock(
            game: widget.game,
            deadline: room.deadline,
            label: 'Voting ends in',
          ),
          const SizedBox(height: 12),
          if (voter && !_voted) ...[
            const Text('Who won?', textAlign: TextAlign.center),
            // Left is red and right is blue, like the two sides of the screen.
            for (final id in [left!, right!])
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: id == left
                        ? const Color(0xFFE63946)
                        : const Color(0xFF1D3FBB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(110),
                  ),
                  onPressed: () => _vote(id),
                  child: Text(
                    '${room.nameOf(id)}\n${room.songs[id]?.title ?? ''}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ] else if (voter)
            const Text('Vote recorded.')
          else
            Text(isContestant ? 'The voters are choosing.' : 'Voting is open.'),
        ];
      case GamePhase.result:
        final result = room.results[room.roundKey];
        if (result == null) return [const Text('Counting votes...')];
        final detail = switch (result.reason) {
          'forfeit' => 'The other contestant did not pick a song.',
          'noSongs' => 'Neither contestant picked a song.',
          _ =>
            'Votes: ${_who(left)} ${result.leftVotes}, ${_who(right)} ${result.rightVotes}',
        };
        return [
          Pop(
            child: Text(
              result.winnerId == 'draw'
                  ? 'Draw: nobody scores'
                  : '${room.nameOf(result.winnerId)} wins the round',
              style: big,
              textAlign: TextAlign.center,
            ),
          ),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _scoreboard(),
          const SizedBox(height: 16),
          if (!isHost)
            const Text('Waiting for the host.', textAlign: TextAlign.center)
          else if (room.roundNumber < gameRounds)
            _hostButton('Next round', () => widget.game.nextRound(room))
          else
            _hostButton(
              'Show final results',
              () => widget.game.showFinal(room),
            ),

          if (isHost && room.roundNumber < gameRounds) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _swap,
              child: const Text('Swap a contestant'),
            ),
          ],
        ];
      case GamePhase.finished:
        final leaders = room.leaders;
        final top = leaders.isEmpty ? 0 : room.scores[leaders.first]!;
        final verdict = top == 0
            ? 'Nobody won a round.'
            : leaders.length == 1
            ? '${room.nameOf(leaders.first)} is the DJ King!'
            : 'Tie: ${leaders.map(room.nameOf).join(', ')}';
        return [
          Pop(
            child: Text(verdict, style: big, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          _scoreboard(),
          if (isHost) ...[
            const SizedBox(height: 16),
            _hostButton(
              'Play again with new contestants',
              () => widget.game.newGame(room),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  runAction(context, () => widget.game.closeRoom(room)),
              child: const Text('End room'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Text('Waiting for the host.', textAlign: TextAlign.center),
          ],
        ];
      case GamePhase.lobby:
      case GamePhase.closed:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Round ${room.roundNumber} of $gameRounds',
          style: theme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (room.phase != GamePhase.contestants &&
            room.leftId != null &&
            room.rightId != null)
          Text(
            '${_who(room.leftId)} vs ${_who(room.rightId)}',
            style: theme.titleMedium,
            textAlign: TextAlign.center,
          ),
        if (room.phase != GamePhase.genre && room.genre != null)
          Text('Genre: ${room.genre}', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        // Song phases swap instantly so two videos never overlap while one slides out.
        AnimatedSwitcher(
          duration: isPlaying
              ? Duration.zero
              : const Duration(milliseconds: 350),
          transitionBuilder: slideFade,
          child: Column(
            key: ValueKey('${room.roundKey}-${room.phase.name}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _phase(),
          ),
        ),
      ],
    );
  }
}
