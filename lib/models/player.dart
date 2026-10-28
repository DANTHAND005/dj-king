class Player {
  const Player({
    required this.id,
    required this.nickname,
    this.connected = true,
  });

  final String id;
  final String nickname;
  final bool connected;

  factory Player.fromMap(String id, Map<String, dynamic> data) => Player(
    id: id,
    nickname: data['nickname'] as String,
    connected: data['connected'] == true,
  );
}
