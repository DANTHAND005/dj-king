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

## Song-picker checks performed on October 25, 2026

- All ten automated tests pass, including square layout, selection, loading, malformed responses, quota errors, and immediate search failures.
- Live YouTube search for `jazz piano` returned eight results inside the square.
- A result was selected without automatically starting playback; the selected title and channel appeared below the square.
- Manual playback of the selected result advanced past 20 seconds, and `Stop song` stopped it.
- The live results, selected title, and playback controls fit a 390px browser viewport without horizontal overflow; no browser errors were recorded.
- The search key is excluded from Git and restricted to YouTube Data API v3 and the current local preview origin.
- This is a standalone picker/playback check. Shared submission deadlines and host-controlled round playback are not implemented yet.

## Automated checks

The current local battle preview has 14 passing tests. Countdown tests verify one transition after five seconds and cancellation when leaving; playback-order tests verify left, right, and a stable finished state.

```powershell
flutter analyze
flutter test
flutter build web
```

## Local battle browser checks on October 25, 2026

- Chose different left and right songs from live YouTube search.
- Verified the visible five-second countdown automatically opened the separate battle screen.
- Verified the left song played first and the right waited.
- After seeking near the left song's ending and letting it finish, verified automatic playback of the right song with the left marked `Finished`.
- Ended the right song and verified the player was removed and both sides were marked finished.
- Verified the manual early-stop handoff with the same video selected on both sides; the right side did not get skipped.
- Checked the battle at 390px width with no horizontal overflow.
- These checks do not verify multiplayer synchronization or native phone behavior.

## Connection test on two phones

1. Run the app on Android and iPhone. Both should move from the loading message to a player ID.
2. Confirm the IDs are different on the two phones.
3. Close and reopen the app. Each installation should keep its ID.
4. Try a fresh launch without internet. If sign-in fails, restore the connection and use `Try again`.

Two tabs in the same browser profile share sign-in storage and normally show the same ID. For a web-only smoke test, use different browsers or isolated profiles. This does not replace native phone testing.

## Playback test on each intended host phone

1. Open `Choose a song` with the YouTube API configuration supplied at build time.
2. Submit an empty search. A validation message should appear without a request.
3. Search for a song or artist. Results should scroll inside the square, with titles, channels, thumbnails, and `Pick this song` buttons.
4. Pick the left contestant's song, then pick the right contestant's song. No song should play during selection.
5. Verify the countdown starts at five and automatically opens `Song battle` once.
6. The left panel should be active and the right panel should say `Up next`. Tap YouTube's Play control if the browser blocks autoplay.
7. Let the left song finish, or use `End left song and play right`. Left audio must stop before the right song starts. Left should say `Finished`; right should become active.
8. Finish or end the right song. The screen should say `Both songs are finished`, with no audio continuing.
9. If a result is unavailable or refuses embedding, verify `Retry song` and `Skip unavailable song` work without overlapping audio.
10. Go back during a countdown and wait. It must not open the battle screen after leaving.
11. Rotate the phone and check that both panels, the player, and buttons remain usable. Both sides use a single shared player below the panels so playback cannot overlap.

A correctly formatted link is not proof that YouTube will allow playback. Regional, age, account, network, and embedding restrictions can still prevent it. The app uses a visible YouTube player and does not extract audio or bypass restrictions.

## Approval boundary

Record phone model, OS, playback result, and any error before approving Stage 2. Lobby creation, joining, and database access rules belong to that next stage.
