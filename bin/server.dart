import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:youtube_monitor/services/youtube_service.dart';
import 'package:youtube_monitor/services/storage_service.dart';
import 'package:youtube_monitor/views/dashboard.dart';

void main() async {
  final youtubeService = YouTubeService();
  final storageService = StorageService();

  final router = Router()
    // Dashboard
    ..get('/', (Request request) async {
      final channels = await storageService.loadChannels();
      return Response.ok(
        DashboardView.render(channels),
        headers: {'Content-Type': 'text/html'},
      );
    })

    // Add channel
    ..post('/api/channels/add', (Request request) async {
      final body = await request.readAsString();
      final data = json.decode(body);
      final username = data['username'] as String;

      // Check if it's a channel ID or username
      String? channelId;
      if (username.startsWith('UC') && username.length == 24) {
        channelId = username;
      } else {
        channelId = await youtubeService.getChannelIdFromUsername(username);
      }

      if (channelId == null) {
        return Response.notFound('Channel not found');
      }

      final channel = await storageService.addChannel(username, channelId);
      return Response.ok(json.encode(channel.toJson()));
    })

    // Remove channel
    ..delete('/api/channels/<id>', (Request request, String id) async {
      await storageService.removeChannel(id);
      return Response.ok('Channel removed');
    })

    // Fetch videos for a channel
    ..get('/api/channels/<channelId>/videos',
        (Request request, String channelId) async {
      final videos = await youtubeService.fetchChannelVideos(channelId);
      return Response.ok(
        json.encode(videos.map((v) => v.toJson()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    })

    // Generate combined report
    ..get('/api/reports/all', (Request request) async {
      final channels = await storageService.loadChannels();

      int totalVideos = 0;
      int totalViews = 0;
      int totalLikes = 0;

      for (final channel in channels) {
        final videos =
            await youtubeService.fetchChannelVideos(channel.channelId);
        totalVideos += videos.length;
        totalViews += videos.fold(0, (sum, v) => sum + v.viewCount);
        totalLikes += videos.fold(0, (sum, v) => sum + v.likeCount);
      }

      return Response.ok(json.encode({
        'totalChannels': channels.length,
        'totalVideos': totalVideos,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
      }));
    });

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, '0.0.0.0', 8888);
  print('Server running on http://${server.address.host}:${server.port}');
}
