class Video {
  final String videoId;
  final String title;
  final String link;
  final DateTime publishedAt;
  final String author;
  final int viewCount;
  final int likeCount;
  final String thumbnailUrl;

  Video({
    required this.videoId,
    required this.title,
    required this.link,
    required this.publishedAt,
    required this.author,
    required this.viewCount,
    required this.likeCount,
    required this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'link': link,
        'publishedAt': publishedAt.toIso8601String(),
        'author': author,
        'viewCount': viewCount,
        'likeCount': likeCount,
        'thumbnailUrl': thumbnailUrl,
      };
}
