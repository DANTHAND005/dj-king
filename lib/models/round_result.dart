class RoundResult {
  const RoundResult({
    required this.winnerId,
    this.leftVotes = 0,
    this.rightVotes = 0,
    this.reason = 'votes',
  });

  final String winnerId;
  final int leftVotes;
  final int rightVotes;
  final String reason;

  factory RoundResult.fromMap(Map<String, dynamic> data) => RoundResult(
    winnerId: data['winnerId'] as String,
    leftVotes: (data['leftVotes'] as num).toInt(),
    rightVotes: (data['rightVotes'] as num).toInt(),
    reason: data['reason'] as String,
  );

  Map<String, dynamic> toMap() => {
    'winnerId': winnerId,
    'leftVotes': leftVotes,
    'rightVotes': rightVotes,
    'reason': reason,
  };

  factory RoundResult.tally({
    required String leftId,
    required String rightId,
    required Set<String> voters,
    required Map<String, dynamic> votes,
  }) {
    var left = 0;
    var right = 0;
    for (final voter in voters) {
      if (voter == leftId || voter == rightId) continue;
      if (votes[voter] == leftId) left++;
      if (votes[voter] == rightId) right++;
    }
    var winner = 'draw';
    if (left > right) winner = leftId;
    if (right > left) winner = rightId;
    return RoundResult(winnerId: winner, leftVotes: left, rightVotes: right);
  }
}
