class Channel {
  final String id;
  final String username;
  final String channelId;
  final DateTime addedAt;

  Channel({
    required this.id,
    required this.username,
    required this.channelId,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'channelId': channelId,
        'addedAt': addedAt.toIso8601String(),
      };

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'],
        username: json['username'],
        channelId: json['channelId'],
        addedAt: DateTime.parse(json['addedAt']),
      );
}
