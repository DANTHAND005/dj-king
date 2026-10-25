import 'package:dj_king/models/battle_order.dart';
import 'package:dj_king/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const left = Song(
    videoId: 'M7lc1UVf-VE',
    title: 'Left song',
    channel: 'Test',
    thumbnailUrl: 'https://example.com/left.jpg',
  );
  const right = Song(
    videoId: 'j4lDDQTKN8s',
    title: 'Right song',
    channel: 'Test',
    thumbnailUrl: 'https://example.com/right.jpg',
  );

  test('plays left, then right, then remains finished', () {
    final order = BattleOrder(left: left, right: right);
    expect(order.currentSong, same(left));
    expect(order.position, 0);
    order.advance();
    expect(order.currentSong, same(right));
    expect(order.finished, isFalse);
    order.advance();
    expect(order.finished, isTrue);
    expect(order.currentSong, isNull);
    order.advance();
    expect(order.position, 2);
  });

  test('the same video can be chosen for both contestants', () {
    final order = BattleOrder(left: left, right: left);
    order.advance();
    expect(order.currentSong, same(left));
    expect(order.finished, isFalse);
    order.advance();
    expect(order.finished, isTrue);
  });
}
