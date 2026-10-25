import 'dart:async';

import 'package:dj_king/models/song.dart';
import 'package:dj_king/services/youtube_search_service.dart';
import 'package:dj_king/widgets/song_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const song = Song(
  videoId: 'M7lc1UVf-VE',
  title: 'Test song',
  channel: 'Test channel',
  thumbnailUrl: 'https://i.ytimg.com/vi/M7lc1UVf-VE/mqdefault.jpg',
);

void main() {
  testWidgets('searches on submit and selects inside a phone-sized square', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final results = Completer<List<Song>>();
    String? selectedId;
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, update) => SongPicker(
                search: (query) {
                  requests++;
                  expect(query, 'test artist');
                  return results.future;
                },
                selectedId: selectedId,
                onSelected: (song) => update(() => selectedId = song.videoId),
              ),
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(SongPicker));
    expect(size.width, size.height);
    await tester.enterText(find.byType(TextFormField), 'test artist');
    expect(requests, 0);
    await tester.tap(find.byTooltip('Search YouTube'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    results.complete([song]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick this song'));
    await tester.pumpAndSettle();
    expect(selectedId, song.videoId);
    expect(find.text('Selected'), findsOneWidget);
    expect(requests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows validation, search errors, and empty results', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: SongPicker(
              search: (_) async {
                if (requests++ == 0) {
                  throw const YoutubeSearchException('Search is offline.');
                }
                return [];
              },
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Search YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a song or artist.'), findsOneWidget);
    expect(requests, 0);
    await tester.enterText(find.byType(TextFormField), 'test');
    await tester.tap(find.byTooltip('Search YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('Search is offline.'), findsOneWidget);
    await tester.tap(find.byTooltip('Search YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('No videos found. Try another search.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
