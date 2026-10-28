# DJ King

A Flutter/Dart class project: a Kahoot-style music battle. The host makes a room, friends join with a 4-letter code, and each of five rounds two random players pick a YouTube song in a random genre. The host's phone plays both songs, everyone else votes, and the most round wins takes the crown.

Live at https://dj-king-c5353.web.app

## How a round goes

1. Host starts the game (3 or more players besides the host).
2. Host picks two random contestants. They stay the same for all five rounds.
3. Each round the host picks a random genre, then both contestants search YouTube and submit a song before a shared deadline. A contestant who misses it forfeits.
4. Five-second countdown, then the host's phone plays the left song, then the right. A contestant can stop their own song.
5. Everyone else votes. A tie or no votes is a draw that scores nobody.
6. After five rounds the final screen shows the two contestants' scores. Ties are shown as ties. The host can then start a new game with two newly picked contestants and fresh scores.

The host only presents: it does not play or vote. A video that will not play lets the host ask that contestant to pick again.

## Code layout

```text
lib/
  main.dart, app.dart        Entry point, purple theme
  firebase_options.dart      Public Firebase identifiers
  models/                    Room, Player, Song, RoundResult (plain data + scoring)
  services/
    game_service.dart        Every Firebase read and write; host-only changes run in one transaction
    youtube_search_service.dart
  screens/
    connection_screen.dart   Sign-in, then the front page
    home_screen.dart         Join with a code or host a game
    lobby_screen.dart        Live player list, leave handling, switches to the game
    game_view.dart           One block per phase; the host copy drives the timers
  widgets/                   Clock, HostPlayer, SongPicker, animations
  utils/                     YouTube link check, snackbar action runner, small helpers
test/                        Mirrors lib/
tools/firebase-tests/        Security rules tests (emulator)
```

No state-management framework: Firebase streams feed `StreamBuilder`, and `setState` handles temporary UI.

## Run and check

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 52943 --dart-define-from-file=config/youtube.local.json
```

Copy `config/youtube.example.json` to the ignored `config/youtube.local.json` and add a YouTube Data API v3 key. The key is visible in the built web app, so restrict it to that API and to the real web origins (`http://127.0.0.1:52943/*` and `https://dj-king-c5353.web.app/*`).

## Firebase

- Project `dj-king-c5353`, Realtime Database in `us-central1`, anonymous sign-in on.
- Security rules are in `database.rules.json` and tested with the emulator:

```powershell
cd tools/firebase-tests; npm install; cd ../..
tools\firebase-tests\node_modules\.bin\firebase.cmd emulators:exec --only database --project dj-king-c5353 "node --test tools/firebase-tests/rules.test.mjs"
```

- Deploy rules and site after `flutter build web --dart-define-from-file=config/youtube.local.json`:

```powershell
tools\firebase-tests\node_modules\.bin\firebase.cmd deploy --only database,hosting --project dj-king-c5353
```

- Private GitHub repository: DANTHAND005/dj-king.

## Not done

- Real Android and iPhone testing.
- Old rooms are never deleted from the database.
