import '../utils/database_value.dart';
import 'player.dart';
import 'round_result.dart';
import 'song.dart';

enum GamePhase {
  lobby,
  contestants,
  genre,
  submission,
  countdown,
  songA,
  songB,
  voting,
  result,
  finished,
  closed,
}

const gameRounds = 5;

/// The 50 genres, roughly most popular first. A game uses all of them or the host's 10.
const gameGenres = [
  'Pop',
  'Hip-hop',
  'Rock',
  'R&B',
  'Country',
  'Electronic',
  'Latin',
  'K-pop',
  'Reggaeton',
  'Afrobeats',
  'Indie',
  'Alternative',
  'Jazz',
  'Classical',
  'Soul',
  'Metal',
  'Lo-fi',
  'Trap',
  'Punk',
  'Reggae',
  'Funk',
  'Disco',
  'Blues',
  'Folk',
  'House',
  'Techno',
  'Dance pop',
  'Synth-pop',
  'Hyperpop',
  'Phonk',
  'Amapiano',
  'Salsa',
  'Bachata',
  'Gospel',
  'Grunge',
  'Pop-punk',
  'Emo',
  'Classic rock',
  'Psychedelic rock',
  'New wave',
  'Dancehall',
  'Drum and bass',
  'Dubstep',
  'Ambient',
  'Bossa nova',
  'Ska',
  'Soundtracks',
  'Hard rock',
  'Latin pop',
  'Motown',
];

class Room {
  Room.fromMap(this.code, Map<String, dynamic> data)
    : hostId = data['hostId'] as String,
      hostName = data['hostName'] as String,
      hostOnline = data['hostOnline'] == true,
      phase = GamePhase.values.byName(data['phase'] as String),
      roundNumber = (data['round'] as num).toInt(),
      revision = (data['revision'] as num).toInt(),
      leftId = data['leftId'] as String?,
      rightId = data['rightId'] as String?,
      genre = data['genre'] as String?,
      genres = (data['genres'] as String?)?.split('|') ?? gameGenres,
      deadline = (data['deadline'] as num?)?.toInt(),
      notice = data['notice'] as String?,
      players = databaseMap(data['players']).map(
        (id, value) => MapEntry(id, Player.fromMap(id, databaseMap(value))),
      ),
      songs = databaseMap(data['songs'])
          .map((id, value) => MapEntry(id, Song.fromMap(databaseMap(value)))),
      results = databaseMap(data['results']).map(
        (key, value) => MapEntry(key, RoundResult.fromMap(databaseMap(value))),
      ),
      voters = databaseMap(data['voters']).keys.toSet();

  final String code;
  final String hostId;
  final String hostName;
  final bool hostOnline;
  final GamePhase phase;
  final int roundNumber;
  final int revision;
  final String? leftId;
  final String? rightId;
  final String? genre;
  final List<String> genres; // the wheel's genres: all 50 or the host's 10
  final int? deadline;
  final String? notice;
  final Map<String, Player> players;
  final Map<String, Song> songs;
  final Map<String, RoundResult> results;
  final Set<String> voters;

  String get roundKey => 'r$roundNumber';
  List<Player> get connectedPlayers =>
      players.values.where((player) => player.connected).toList();
  String? get activeContestant => switch (phase) {
    GamePhase.songA => leftId,
    GamePhase.songB => rightId,
    _ => null,
  };
  String nameOf(String? id) => players[id]?.nickname ?? 'Player';

  Map<String, int> get scores {
    final scores = {for (final id in players.keys) id: 0};
    for (final result in results.values) {
      if (scores.containsKey(result.winnerId)) {
        scores[result.winnerId] = scores[result.winnerId]! + 1;
      }
    }
    return scores;
  }

  List<String> get leaders {
    final totals = scores;
    if (totals.isEmpty) return [];
    final best = totals.values.reduce((a, b) => a > b ? a : b);
    return totals.keys.where((id) => totals[id] == best).toList();
  }
}
