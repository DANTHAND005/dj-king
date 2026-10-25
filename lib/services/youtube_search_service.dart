import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/song.dart';

class YoutubeSearchException implements Exception {
  const YoutubeSearchException(this.message);
  final String message;
}

class YoutubeSearchService {
  YoutubeSearchService({
    http.Client? client,
    this.apiKey = const String.fromEnvironment('YOUTUBE_API_KEY'),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;

  Future<List<Song>> search(String query) async {
    if (query.trim().isEmpty) return [];
    if (apiKey.isEmpty) {
      throw const YoutubeSearchException(
        'Song search needs to be enabled for this app.',
      );
    }

    try {
      final response = await _client
          .get(
            Uri.https('www.googleapis.com', '/youtube/v3/search', {
              'key': apiKey,
              'part': 'snippet',
              'type': 'video',
              'videoEmbeddable': 'true',
              'videoSyndicated': 'true',
              'safeSearch': 'moderate',
              'maxResults': '8',
              'q': query.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final reason = body['error']?['errors']?[0]?['reason'];
        throw YoutubeSearchException(
          const {'quotaExceeded', 'dailyLimitExceeded'}.contains(reason)
              ? 'YouTube search has reached its daily limit. Try again later.'
              : 'YouTube search is unavailable. Please try again later.',
        );
      }
      final items = body['items'] as List;
      return items
          .map((item) => Song.fromSearchResult(item as Map<String, dynamic>))
          .toList();
    } on YoutubeSearchException {
      rethrow;
    } on TimeoutException {
      throw const YoutubeSearchException(
        'Search took too long. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const YoutubeSearchException(
        'Could not reach YouTube. Check your connection and try again.',
      );
    } on FormatException {
      throw const YoutubeSearchException(
        'YouTube returned an unreadable result. Try again.',
      );
    } on TypeError {
      throw const YoutubeSearchException(
        'YouTube returned an unreadable result. Try again.',
      );
    } on RangeError {
      throw const YoutubeSearchException(
        'YouTube search is unavailable. Please try again later.',
      );
    }
  }

  void close() => _client.close();
}
