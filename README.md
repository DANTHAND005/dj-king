# DJ King

A Flutter/Dart class project: join a host's lobby, randomly choose two contestants and a genre, submit YouTube songs, listen on the host's phone, and vote. Play five rounds; most round wins wins. Players can be selected again in consecutive rounds.

## Current stage: 1 (connection and playback check)

The app signs in anonymously, displays the player's ID, and opens a square YouTube song picker with a separate playback test. Player, Room, and Song models are defined; lobby and game features are not implemented yet. Picking a song does not start playback. The shared round timer and host playback come with later game stages. The real-phone checkpoint is pending.

## File organization

```text
lib/
  main.dart                     Entry point
  app.dart                      App shell
  firebase_options.dart         Public Firebase identifiers for all three platforms
  models/
    player.dart                 Player ID and nickname
    room.dart                   Room identity, phase, and round number
    song.dart                   Video ID and YouTube search metadata
  services/
    game_service.dart           Firebase initialization and anonymous sign-in
    youtube_search_service.dart Official YouTube search requests and errors
  screens/
    connection_screen.dart      Loading, connection errors, player ID, retry
    playback_screen.dart        Song selection, play/stop test, playback errors
  widgets/
    song_picker.dart            Bordered square with search and selection
  utils/
    youtube_link.dart           Validates supported links and extracts video IDs
test/
  widget_test.dart               Connection loading, success, and retry
  utils/youtube_link_test.dart   Link validation and malformed input checks
  services/                     YouTube request and response checks
  widgets/                      Song-picker interaction and phone-width checks
```

No state-management framework or model generator is used. Firebase client identifiers in `firebase_options.dart` are public configuration, not admin credentials. Anonymous sign-in does not grant access to the locked database.

Created with Flutter 3.47.7 and Dart 3.13.5. Commit `pubspec.lock` and use the same Flutter version on both developers' machines.

### Run and check

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 52943 --dart-define-from-file=config/youtube.local.json
```

### Enable YouTube song search

Live search needs YouTube Data API v3 enabled in `dj-king-c5353` and a dedicated API key restricted to that API. Do not reuse an admin credential. A web client key is visible in the built application, so also restrict it to the actual web origins in Google Cloud.

The API is now enabled. This machine's ignored local configuration uses the dedicated `DJ King local web YouTube search` key, restricted to YouTube Data API v3 and `http://127.0.0.1:52943/*`. A clone needs its own local configuration; the key is not committed.

Copy `config/youtube.example.json` to the ignored `config/youtube.local.json` and fill in the restricted key. For the existing local preview origin, use:

```powershell
flutter build web --dart-define-from-file=config/youtube.local.json
python -m http.server 52943 --bind 127.0.0.1 --directory build/web
```

Use either the Flutter development server or the static preview server on port 52943, not both at once. Stop the existing server before starting another on that port.

For native testing, configure a suitable separate restricted client key for that platform and pass its configuration with `--dart-define-from-file`. Do not remove the web key's origin restrictions to make native testing work.

Search happens only on submission, returns up to eight embeddable video results, and has no automatic pagination. The list scrolls inside the square. Search results do not guarantee playback in every region or on every device. Missing configuration, network errors, empty results, and quota limits are shown explicitly.

### Real Android phone test

1. Install [Android Studio and the Android SDK](https://docs.flutter.dev/platform-integration/android/setup). Run `flutter doctor` and address its Android toolchain checks, including `flutter doctor --android-licenses` when prompted.
2. Enable Developer options and USB debugging on the phone, connect it by USB, and accept its computer authorization prompt.
3. Run `flutter devices`, then `flutter run -d <device-id>` using the phone's listed ID.
4. Confirm a player ID appears. Rotate the phone, then close and reopen the app; the ID should stay the same.
5. Follow the [Stage 1 phone checklist](docs/stage-1-testing.md) on Android and iPhone before moving on.

Building the native iOS app requires macOS and Xcode; this Windows machine cannot perform that test.

### Firebase and GitHub

- Firebase project: `dj-king-c5353` (the existing DJ KING project in your account).
- Anonymous Authentication is enabled.
- Web, Android (`com.example.dj_king`), and iOS (`com.example.djKing`) apps are registered. Firebase is initialized using the explicit platform options in `lib/firebase_options.dart`; no native Google sign-in or Analytics integration is included.
- Realtime Database: `https://dj-king-c5353-default-rtdb.firebaseio.com`, located in `us-central1`. Both client reads and writes remain denied until Stage 2 adds lobby access rules. The matching locked rules are tracked in `database.rules.json`. Do not put admin credentials or service-account keys in the app.
- Private GitHub repository: [DANTHAND005/dj-king](https://github.com/DANTHAND005/dj-king). Its local repository is independent of the surrounding workspace. Abdullahi's invitation is deferred at your request.

### Remaining setup

- Install the missing Android SDK and connect a physical phone. Native iOS verification requires a Mac with Xcode.
- Pass the Stage 1 real-phone tests before approving Stage 2.

## Approved direction

Use one app with phase widgets, one Firebase game service, and plain Room, Player, and Round models. Firebase stores shared state; Flutter's `StreamBuilder` displays updates and `setState` manages temporary UI state.

The host saves random selections once. A contestant cannot face themselves. Store votes by voter UID and calculate scores from the five recorded round results. Use one shared deadline, not a database write every second.

Add dependencies only as needed: `firebase_core`, `firebase_auth`, `firebase_database`, `flutter_fortune_wheel`, `youtube_player_iframe`, and `wakelock_plus`.

## Next stages and phone checkpoints

| Stage | Work | Phone checkpoint |
| --- | --- | --- |
| 1 | Firebase, anonymous sign-in, models, early playback experiment | Two phones show different UIDs; host plays, stops, and switches videos. |
| 2 | Room code, joining, live player list, access rules | Three phones see the same live membership. |
| 3 | Saved phase and host transitions | Host advances every phone; double taps cannot skip a phase. |
| 4 | Contestant wheel and genre wheel | Every phone sees the same two different contestants and genre. |
| 5 | Validated YouTube submissions and deadline | Both contestants submit; invalid and late writes fail. |
| 6 | Host playback and contestant stop requests | Both songs play and the correct stop request works. |
| 7 | Voting, round results, five-round scoreboard | A full game finishes without duplicate votes or wins. |
| 8 | Disconnects, recovery, wake lock, rule checks | Five-phone test survives someone dropping out. |

Commit after each stage. Song search, Spotify, confetti, and persistent game history are deferred.

Still to decide before their implementation: whether the host also plays/votes, round and final ties, submission timeout behavior, and interrupted-round recovery.
