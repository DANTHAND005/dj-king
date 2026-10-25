import 'package:dj_king/utils/youtube_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'M7lc1UVf-VE';

  test('accepts supported YouTube links and ignores sharing parameters', () {
    for (final link in [
      'https://www.youtube.com/watch?v=$id',
      'https://youtube.com/watch?feature=shared&v=$id',
      ' https://youtu.be/$id?si=shared ',
      'https://m.youtube.com/watch?v=$id&t=30s',
      'https://music.youtube.com/watch?v=$id',
      'https://www.youtube.com/shorts/$id',
      'https://www.youtube.com/embed/$id',
    ]) {
      expect(youtubeVideoId(link), id, reason: link);
    }
  });

  test('rejects malformed IDs, unrelated hosts, and unsupported URLs', () {
    for (final link in [
      '',
      id,
      'http://youtu.be/$id',
      'https://example.com/watch?v=$id',
      'https://youtube.com.example.com/watch?v=$id',
      'https://youtube.com@evil.example/watch?v=$id',
      'https://user@youtube.com/watch?v=$id',
      'https://youtu.be/${id}extra',
      'https://youtu.be/$id/extra',
      'https://www.youtube.com/watch?v=short',
      'https://www.youtube.com/watch?v=!!!!!!!!!!!',
      'https://www.youtube.com/playlist?list=$id',
      'https://youtu.be/%FF',
      'https://www.youtube.com/watch?v=%FF',
    ]) {
      expect(youtubeVideoId(link), isNull, reason: link);
    }
  });
}
