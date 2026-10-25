# Stage 1 checkpoint

Status: real Android and iPhone tests have not been run.

## Browser checks performed on October 25, 2026

- Edge and the app's embedded browser connected with different anonymous player IDs.
- Both sessions retained their IDs after reloading the final build.
- The playback form and controls fit a 360px browser viewport without horizontal overflow.
- A lookalike YouTube domain was rejected by the form.
- The YouTube API demonstration video played for several seconds; `Stop song` stopped it.
- A second video from the package's examples loaded into the same player, played, and stopped.
- Loading and sign-in retry are covered by widget tests; actual offline recovery is still a phone-check item.
- Native playback, a complete song, and embedding-restriction recovery have not been verified.

## Automated checks

```powershell
flutter analyze
flutter test
flutter build web
```

## Connection test on two phones

1. Run the app on Android and iPhone. Both should move from the loading message to a player ID.
2. Confirm the IDs are different on the two phones.
3. Close and reopen the app. Each installation should keep its ID.
4. Try a fresh launch without internet. If sign-in fails, restore the connection and use `Try again`.

Two tabs in the same browser profile share sign-in storage and normally show the same ID. For a web-only smoke test, use different browsers or isolated profiles. This does not replace native phone testing.

## Playback test on each intended host phone

1. Open `Test song playback`.
2. Try an invalid link. A validation message should appear without loading it.
3. Paste a public YouTube video link, press `Load song`, then press play inside the video.
4. Verify audible playback. Press `Stop song`; audio should stop.
5. Load a different video and verify playback again.
6. Try a video that disallows embedding, if one is available. The app should ask for a replacement, without crashing.
7. Go back, then reopen the playback test. There should be no old audio playing.
8. Rotate the phone and check that the input, player, and buttons remain usable.

A correctly formatted link is not proof that YouTube will allow playback. Regional, age, account, network, and embedding restrictions can still prevent it. The app uses a visible YouTube player and does not extract audio or bypass restrictions.

## Approval boundary

Record phone model, OS, playback result, and any error before approving Stage 2. Lobby creation, joining, and database access rules belong to that next stage.
