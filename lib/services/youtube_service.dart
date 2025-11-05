import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/video.dart';

class YouTubeService {
  static const String rssBaseUrl = 'https://www.youtube.com/feeds/videos.xml';

  /// Fetch channel RSS feed and parse videos
  Future<List<Video>> fetchChannelVideos(String channelId) async {
    final url = Uri.parse('$rssBaseUrl?channel_id=$channelId');

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch channel feed: ${response.statusCode}');
      }

      return _parseRssFeed(response.body);
    } catch (e) {
      print('Error fetching channel $channelId: $e');
      return [];
    }
  }

  /// Parse XML RSS feed from YouTube
  List<Video> _parseRssFeed(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final entries = document.findAllElements('entry');

    return entries.map((entry) {
      final videoId = _extractText(entry, 'yt:videoId');
      final title = _extractText(entry, 'title');
      final link = entry.findElements('link').first.getAttribute('href') ?? '';
      final published = _extractText(entry, 'published');
      final author = _extractText(entry, 'author')
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .first
          .trim();

      // Extract media statistics
      final mediaGroup = entry.findElements('media:group').first;

      final mediaCommunity =
          mediaGroup.findElements('media:community').firstOrNull;

      final mediaStats =
          mediaCommunity?.findElements('media:statistics').firstOrNull;

      ///
      final viewCount =
          int.tryParse(mediaStats?.getAttribute('views') ?? '0') ?? 0;

      final mediaStarRating =
          mediaCommunity?.findElements('media:starRating').firstOrNull;
      final likeCount =
          int.tryParse(mediaStarRating?.getAttribute('count') ?? '0') ?? 0;

      // Get thumbnail
      final mediaThumbnail =
          mediaGroup.findElements('media:thumbnail').firstOrNull;
      final thumbnailUrl = mediaThumbnail?.getAttribute('url') ?? '';

      return Video(
        videoId: videoId,
        title: title,
        link: link,
        publishedAt: DateTime.parse(published),
        author: author,
        viewCount: viewCount,
        likeCount: likeCount,
        thumbnailUrl: thumbnailUrl,
      );
    }).toList();
  }

  String _extractText(XmlElement element, String tagName) {
    final found = element.findElements(tagName).firstOrNull;
    return found?.innerText ?? '';
  }

  /// Fetch channel ID from username (requires page source scraping)
  Future<String?> getChannelIdFromUsername(String username) async {
    final url = Uri.parse('https://www.youtube.com/@$username');

    /// https://www.youtube.com/@Impacttvmanipur/videos

    try {
      final response = await http.get(url);

      print(response.statusCode);
      if (response.statusCode != 200) {
        return null;
      }

      // Extract channel ID from page source
      final pattern = RegExp(r'"https://www.youtube.com/channel/([^"]+)"');
      final match = pattern.firstMatch(response.body);

      return match?.group(1);
    } catch (e) {
      print('Error fetching channel ID for $username: $e');
      return null;
    }
  }
}
