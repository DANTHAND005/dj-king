# DJ King

A Flutter/Dart class project: join a host's lobby, randomly choose two contestants and a genre, submit YouTube songs, listen on the host's phone, and vote. Play five rounds; most round wins wins. Players can be selected again in consecutive rounds.

## Current stage: 0 (setup)

This is intentionally a blank app displaying `DJ King`. No lobby, Firebase connection, or game features have been implemented. Each later stage requires approval after the preceding stage's real-phone test.

Created with Flutter 3.47.7 and Dart 3.13.5. Commit `pubspec.lock` and use the same Flutter version on both developers' machines.

### Run and check

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

### Real Android phone test

1. Install [Android Studio and the Android SDK](https://docs.flutter.dev/platform-integration/android/setup). Run `flutter doctor` and address its Android toolchain checks, including `flutter doctor --android-licenses` when prompted.
2. Enable Developer options and USB debugging on the phone, connect it by USB, and accept its computer authorization prompt.
3. Run `flutter devices`, then `flutter run -d <device-id>` using the phone's listed ID.
4. Confirm the app opens with `DJ King`, rotate the phone, then close and reopen the app. It should remain usable without errors.

Building the native iOS app requires macOS and Xcode; this Windows machine cannot perform that test.

### Firebase and GitHub

- Firebase project: `dj-king-c5353` (the existing DJ KING project in your account).
- Anonymous Authentication is enabled.
- Realtime Database: `https://dj-king-c5353-default-rtdb.firebaseio.com`, located in `us-central1`. Both client reads and writes are denied until Stage 1 adds appropriate rules and app configuration. The matching locked rules are tracked in `database.rules.json`. Do not put admin credentials or service-account keys in the app.
- Private GitHub repository: [DANTHAND005/dj-king](https://github.com/DANTHAND005/dj-king). Its local repository is independent of the surrounding workspace. Abdullahi's invitation is deferred at your request.

### Remaining setup

- Pass the real-phone test before approving Stage 1.

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
