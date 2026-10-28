import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../firebase_options.dart';
import '../models/room.dart';
import '../models/round_result.dart';
import '../models/song.dart';
import '../utils/database_value.dart';

class GameException implements Exception {
  const GameException(this.message);
  final String message;
}

class GameService {
  int clockOffset = 0;
  int get now => DateTime.now().millisecondsSinceEpoch + clockOffset;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  DatabaseReference roomRef(String code) =>
      FirebaseDatabase.instance.ref('rooms/$code');
  DatabaseReference roundRef(Room room) =>
      FirebaseDatabase.instance.ref('rounds/${room.code}/${room.roundKey}');
  Future<String> signIn() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    if (user == null) throw StateError('Sign-in did not return a player.');
    _watchConnection();
    return user.uid;
  }

  Stream<bool> watchStop(Room room) =>
      roundRef(room)
          .child('stops/${room.activeContestant}')
          .onValue
          .map((event) => event.snapshot.value == true);

  DatabaseReference? _presenceFlag;
  bool _listening = false;

  // Keeps the server clock offset and re-announces presence after a dropped connection.
  void _watchConnection() {
    if (_listening) return;
    _listening = true;
    final db = FirebaseDatabase.instance;
    db
        .ref('.info/serverTimeOffset')
        .onValue
        .listen(
          (event) => clockOffset = (event.snapshot.value as num?)?.toInt() ?? 0,
        );
    db.ref('.info/connected').onValue.listen((event) {
      final flag = _presenceFlag;
      if (event.snapshot.value == true && flag != null) _present(flag);
    });
  }

  // Marks a flag true now and false when this client's connection drops.
  Future<void> _present(DatabaseReference flag) async {
    _presenceFlag = flag;
    await flag.onDisconnect().set(false);
    await flag.set(true);
  }

  Stream<Room?> watchRoom(String code) => roomRef(code).onValue.map(
    (event) => event.snapshot.exists
        ? Room.fromMap(code, databaseMap(event.snapshot.value))
        : null,
  );

  Future<String> createRoom(String nickname) async {
    final random = Random.secure();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = String.fromCharCodes(
        List.generate(4, (_) => 65 + random.nextInt(26)),
      );
      final result = await roomRef(code).runTransaction((value) {
        if (value != null) return Transaction.abort();
        return Transaction.success({
          'hostId': uid,
          'hostName': nickname.trim(),
          'hostOnline': true,
          'createdAt': ServerValue.timestamp,
          'phase': 'lobby',
          'round': 0,
          'revision': 0,
        });
      }, applyLocally: false);
      if (result.committed) {
        await _present(roomRef(code).child('hostOnline'));
        return code;
      }
    }
    throw const GameException('Could not find an unused room code. Try again.');
  }

  Future<String> joinRoom(String input, String nickname) async {
    final code = input.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{4}$').hasMatch(code)) {
      throw const GameException('Enter the four-letter room code.');
    }
    final snapshot = await roomRef(code).get();
    if (!snapshot.exists) {
      throw const GameException('That room does not exist. Check the code.');
    }
    final room = Room.fromMap(code, databaseMap(snapshot.value));
    if (room.phase == GamePhase.closed) {
      throw const GameException('The host has ended that room.');
    }
    if (room.hostId == uid) {
      await _present(roomRef(code).child('hostOnline'));
      return code;
    }
    final existing = room.players[uid];
    if (existing == null && room.phase != GamePhase.lobby) {
      throw const GameException('This game has started. Join the next lobby.');
    }
    await roomRef(code).child('players/$uid').set({
      'nickname': existing?.nickname ?? nickname.trim(),
      'connected': true,
    });
    await _present(roomRef(code).child('players/$uid/connected'));
    return code;
  }

  // Test players, so one person can run a whole game. The host's phone plays for them.
  // ponytail: remove once real friends are playing, or hide behind a debug flag.
  static const _botNames = ['Ava', 'Ben', 'Cleo'];
  static const _botVideos = ['dQw4w9WgXcQ', 'jNQXAC9IHK8', 'M7lc1UVf-VE'];
  final _botDone = <String>{};

  bool isBot(String id) => id.startsWith('bot-');

  Future<void> addBots(Room room) =>
      roomRef(room.code).child('players').update({
        for (final (i, name) in _botNames.indexed)
          'bot-${i + 1}': {'nickname': '$name (bot)', 'connected': true},
      });

  /// Host only, called every tick: bots submit a song when picked and vote when asked.
  Future<void> playBots(Room room) async {
    final left = room.leftId, right = room.rightId;
    if (left == null || right == null) return;
    if (room.phase == GamePhase.submission) {
      for (final id in [left, right].where(isBot)) {
        if (!_botDone.add('${room.roundKey}-song-$id-${room.revision}')) {
          continue;
        }
        final video =
            _botVideos[(id.hashCode + room.roundNumber).abs() %
                _botVideos.length];
        final song = Song(
          videoId: video,
          title: 'Test song ($video)',
          channel: 'Bot',
          thumbnailUrl: 'https://i.ytimg.com/vi/$video/mqdefault.jpg',
        );
        await roundRef(room).child('songs/$id').set(song.toMap());
      }
    }
    if (room.phase == GamePhase.voting) {
      for (final id in room.voters.where(isBot)) {
        if (!_botDone.add('${room.roundKey}-vote-$id-${room.revision}')) {
          continue;
        }
        await roundRef(room)
            .child('votes/$id')
            .set((id.hashCode + room.roundNumber).isEven ? left : right);
      }
    }
  }

  /// Players leave quietly (removed in the lobby, marked offline later); the host closes the room.
  Future<void> leaveRoom(Room room) async {
    final flag = _presenceFlag;
    _presenceFlag = null;
    await flag?.onDisconnect().cancel();
    if (room.phase == GamePhase.closed) return;
    if (room.hostId == uid) return closeRoom(room);
    final me = roomRef(room.code).child('players/$uid');
    await (room.phase == GamePhase.lobby
        ? me.remove()
        : me.child('connected').set(false));
  }

  Future<void> _change(
    Room expected,
    void Function(Map<String, dynamic>) change,
  ) async {
    var failure = 'The room changed. Please try again.';
    final result = await roomRef(expected.code).runTransaction((value) {
      if (value == null) return Transaction.abort();
      final data = databaseMap(value);
      if (data['hostId'] != uid ||
          data['revision'] != expected.revision ||
          data['phase'] != expected.phase.name) {
        return Transaction.abort();
      }
      try {
        change(data);
      } on GameException catch (error) {
        failure = error.message;
        return Transaction.abort();
      }
      data['revision'] = expected.revision + 1;
      return Transaction.success(data);
    }, applyLocally: false);
    if (!result.committed) throw GameException(failure);
  }

  Future<void> nextRound(Room room) => _change(room, (data) {
    final current = Room.fromMap(room.code, data);
    if (current.connectedPlayers.length < 3) {
      throw const GameException('At least three connected players are needed.');
    }
    if (current.roundNumber >= gameRounds) {
      throw const GameException('All five rounds have been played.');
    }
    // The same two contestants play all five rounds, so only round 1 picks them.
    final first = current.roundNumber == 0;
    data['round'] = current.roundNumber + 1;
    data['phase'] = first ? 'contestants' : 'genre';
    for (final field in [
      if (first) ...['leftId', 'rightId'],
      'genre',
      'songs',
      'voters',
      'deadline',
      'notice',
    ]) {
      data.remove(field);
    }
  });

  /// After the final screen: wipe the old rounds and start over with two new contestants.
  Future<void> newGame(Room room) async {
    await FirebaseDatabase.instance.ref('rounds/${room.code}').remove();
    await _change(room, (data) {
      if (Room.fromMap(room.code, data).connectedPlayers.length < 3) {
        throw const GameException(
          'At least three connected players are needed.',
        );
      }
      data['round'] = 1;
      data['phase'] = 'contestants';
      for (final field in [
        'leftId',
        'rightId',
        'genre',
        'songs',
        'voters',
        'deadline',
        'notice',
        'results',
      ]) {
        data.remove(field);
      }
    });
  }

  Future<void> spinContestant(Room room) {
    final candidates = room.connectedPlayers
        .where((player) => player.id != room.leftId)
        .toList();
    if (candidates.isEmpty) {
      throw const GameException('Not enough connected players.');
    }
    final picked = candidates[Random.secure().nextInt(candidates.length)].id;
    return _change(room, (data) {
      if (databaseMap(databaseMap(data['players'])[picked])['connected'] !=
          true) {
        throw const GameException('That player disconnected. Spin again.');
      }
      if (data['rightId'] != null) {
        throw const GameException('Both contestants have already been chosen.');
      }
      data[data['leftId'] == null ? 'leftId' : 'rightId'] = picked;
    });
  }

  /// Lobby only. An empty list means random from all 50 genres.
  Future<void> setGenres(Room room, List<String> picked) =>
      _change(room, (data) {
        if (room.phase != GamePhase.lobby) {
          throw const GameException('Genres can only change in the lobby.');
        }
        if (picked.isEmpty) {
          data.remove('genres');
        } else if (picked.length != 10 || !picked.every(gameGenres.contains)) {
          throw const GameException('Pick exactly 10 genres.');
        } else {
          data['genres'] = picked.join('|');
        }
      });

  /// Host swaps in a different player as the left or right contestant.
  Future<void> setContestant(Room room, bool left, String playerId) =>
      _change(room, (data) {
        final other = data[left ? 'rightId' : 'leftId'];
        final player = databaseMap(databaseMap(data['players'])[playerId]);
        if (player['connected'] != true || playerId == other) {
          throw const GameException('That player cannot play right now.');
        }
        data[left ? 'leftId' : 'rightId'] = playerId;
      });

  Future<void> openGenre(Room room) => _change(room, (data) {
    if (data['leftId'] == null || data['rightId'] == null) {
      throw const GameException('Pick two contestants first.');
    }
    data['phase'] = 'genre';
  });

  Future<void> spinGenre(Room room) {
    final picked = room.genres[Random.secure().nextInt(room.genres.length)];
    return _change(room, (data) {
      if (data['genre'] != null) {
        throw const GameException('The genre is already chosen.');
      }
      data['genre'] = picked;
    });
  }

  Future<void> openSubmission(Room room) => _change(room, (data) {
    if (data['genre'] == null) {
      throw const GameException('Spin the genre wheel first.');
    }
    final voters = room.connectedPlayers.where(
      (player) => player.id != room.leftId && player.id != room.rightId,
    );
    if (voters.isEmpty) {
      throw const GameException('At least one connected voter is needed.');
    }
    data['voters'] = {for (final player in voters) player.id: true};
    data['phase'] = 'submission';
    data['deadline'] = now + 60000;
  });

  Future<void> submitSong(Room room, Song song) =>
      roundRef(room).child('songs/$uid').set(song.toMap());
  Future<void> vote(Room room, String contestant) =>
      roundRef(room).child('votes/$uid').set(contestant);
  Future<void> requestStop(Room room) =>
      roundRef(room).child('stops/$uid').set(true);

  void _recordResult(Map<String, dynamic> data, Room room, RoundResult result) {
    final results = databaseMap(data['results']);
    if (results.containsKey(room.roundKey)) {
      throw const GameException('This round has already been counted.');
    }
    results[room.roundKey] = result.toMap();
    data['results'] = results;
    data['phase'] = 'result';
    data.remove('deadline');
  }

  Future<void> finishSubmission(Room room) async {
    final snapshot = await roundRef(room).child('songs').get();
    final songs = databaseMap(snapshot.value);
    await _change(room, (data) {
      final leftReady = songs.containsKey(room.leftId);
      final rightReady = songs.containsKey(room.rightId);
      if (!leftReady || !rightReady) {
        if (now < (room.deadline ?? 0)) {
          throw const GameException('Song selection is still open.');
        }
        var winner = 'draw';
        if (leftReady) winner = room.leftId!;
        if (rightReady) winner = room.rightId!;
        _recordResult(
          data,
          room,
          RoundResult(
            winnerId: winner,
            reason: winner == 'draw' ? 'noSongs' : 'forfeit',
          ),
        );
      } else {
        data['songs'] = {
          room.leftId!: songs[room.leftId],
          room.rightId!: songs[room.rightId],
        };
        data['phase'] = 'countdown';
        data['deadline'] = now + 5000;
      }
    });
  }

  Future<void> advancePlayback(Room room) => _change(room, (data) {
    switch (room.phase) {
      case GamePhase.countdown:
        if (now < (room.deadline ?? 0)) {
          throw const GameException('The countdown has not finished.');
        }
        data['phase'] = 'songA';
        data.remove('deadline');
      case GamePhase.songA:
        data['phase'] = 'songB';
      case GamePhase.songB:
        data['phase'] = 'voting';
        data['deadline'] = now + 20000;
      default:
        throw const GameException('Playback is not active.');
    }
  });

  Future<void> finishVoting(Room room) async {
    final snapshot = await roundRef(room).child('votes').get();
    final votes = databaseMap(snapshot.value);
    if (now < (room.deadline ?? 0) && !room.voters.every(votes.containsKey)) {
      throw const GameException('Voting is still open.');
    }
    final result = RoundResult.tally(
      leftId: room.leftId!,
      rightId: room.rightId!,
      voters: room.voters,
      votes: votes,
    );
    await _change(room, (data) => _recordResult(data, room, result));
  }

  Future<void> replaceSong(Room room, String contestant) async {
    await roundRef(room).child('songs/$contestant').remove();
    await roundRef(room).child('stops').remove();
    await _change(room, (data) {
      data['phase'] = 'submission';
      data['deadline'] = now + 60000;
      data['notice'] = 'A video could not play. Pick a replacement; this round will restart.';
      data.remove('songs');
    });
  }

  Future<void> showFinal(Room room) => _change(room, (data) {
    data['phase'] = 'finished';
  });
  Future<void> closeRoom(Room room) => _change(room, (data) {
    data['phase'] = 'closed';
    data.remove('deadline');
  });
}
