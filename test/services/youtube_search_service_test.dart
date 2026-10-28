import 'dart:convert';

import 'package:dj_king/services/youtube_search_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'search requests embeddable videos and parses the selected video ID',
    () async {
      final service = YoutubeSearchService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          expect(request.url.host, 'www.googleapis.com');
          expect(request.url.queryParameters['q'], 'test artist');
          expect(request.url.queryParameters['type'], 'video');
          expect(request.url.queryParameters['videoEmbeddable'], 'true');
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': {'videoId': 'M7lc1UVf-VE'},
                  'snippet': {
                    'title': 'Test song',
                    'channelTitle': 'Test channel',
                    'thumbnails': {
                      'medium': {
                        'url':
                            'https://i.ytimg.com/vi/M7lc1UVf-VE/mqdefault.jpg',
                      },
                    },
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.close);

      final songs = await service.search(' test artist ');
      expect(songs.single.videoId, 'M7lc1UVf-VE');
      expect(songs.single.title, 'Test song');
    },
  );

  test('missing configuration does not make a network request', () async {
    final service = YoutubeSearchService(
      apiKey: '',
      client: MockClient((_) async {
        fail('Search must not run without a key.');
      }),
    );
    addTearDown(service.close);
    expect(await service.search(' '), isEmpty);
    await expectLater(
      service.search('artist'),
      throwsA(isA<YoutubeSearchException>()),
    );
  });

  test(
    'quota errors give a useful message without exposing credentials',
    () async {
      final service = YoutubeSearchService(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {
                'errors': [
                  {'reason': 'quotaExceeded'},
                ],
              },
            }),
            403,
          ),
        ),
      );
      addTearDown(service.close);
      await expectLater(
        service.search('artist'),
        throwsA(
          isA<YoutubeSearchException>().having(
            (error) => error.message,
            'message',
            contains('daily limit'),
          ),
        ),
      );
    },
  );

  test(
    'skips items that are not videos instead of failing the search',
    () async {
      final body = jsonEncode({
        'items': [
          {
            'id': {'channelId': 'UC1'},
            'snippet': {
              'thumbnails': {
                'medium': {'url': 'https://x.test/a.jpg'},
              },
            },
          },
          {
            'id': {'videoId': 'dQw4w9WgXcQ'},
            'snippet': {
              'title': 't',
              'channelTitle': 'c',
              'thumbnails': {
                'medium': {'url': 'https://x.test/a.jpg'},
              },
            },
          },
        ],
      });
      final service = YoutubeSearchService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(service.close);
      final songs = await service.search('artist');
      expect(songs.map((s) => s.videoId), ['dQw4w9WgXcQ']);
    },
  );
  test('invalid API responses fail safely', () async {
    for (final body in ['not json', '{"items":[{}]}', '{"items":null}']) {
      final service = YoutubeSearchService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        service.search('artist'),
        throwsA(isA<YoutubeSearchException>()),
      );
      service.close();
    }
  });
}
