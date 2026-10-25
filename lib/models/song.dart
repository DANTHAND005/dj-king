import '../utils/youtube_link.dart';

class Song {
  const Song({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnailUrl,
  });

  final String videoId;
  final String title;
  final String channel;
  final String thumbnailUrl;

  factory Song.fromSearchResult(Map<String, dynamic> result) {
    final identity = result['id'] as Map<String, dynamic>;
    final id = identity['videoId'] as String;
    final snippet = result['snippet'] as Map<String, dynamic>;
    final thumbnails = snippet['thumbnails'] as Map<String, dynamic>;
    final medium = thumbnails['medium'] as Map<String, dynamic>;
    final thumbnail = medium['url'] as String;
    if (youtubeVideoId('https://youtu.be/$id') != id ||
        Uri.tryParse(thumbnail)?.scheme != 'https') {
      throw const FormatException('Invalid YouTube search result.');
    }
    return Song(
      videoId: id,
      title: snippet['title'] as String,
      channel: snippet['channelTitle'] as String,
      thumbnailUrl: thumbnail,
    );
  }
}
