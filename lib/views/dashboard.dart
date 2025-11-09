import 'dart:io';
import '../models/channel.dart';
import '../models/video.dart';
import 'package:intl/intl.dart';

class DashboardView {
  static const String templatePath = 'lib/views/templates/dashboard.html';

  /// Read HTML template from file
  static Future<String> _readTemplate() async {
    final file = File(templatePath);
    if (!await file.exists()) {
      throw Exception('Template file not found: $templatePath');
    }
    return await file.readAsString();
  }

  /// Render dashboard with channels
  static Future<String> render(List<Channel> channels) async {
    final template = await _readTemplate();

    // Generate channel cards HTML
    final channelsHtml =
        channels.reversed.map((channel) => _renderChannelCard(channel)).join();

    ///
    final countsUpdated =
        await template.replaceAll("{{COUNTS}}", channels.length.toString());
    final channelsUpdated =
        await countsUpdated.replaceAll('{{CHANNELS}}', channelsHtml);

    /// Replace placeholders in template
    return channelsUpdated;
  }

  static String _renderChannelCard(Channel channel) {
    final cardId = 'videos-${channel.id}';
    final statsId = 'stats-${channel.id}';
    return '''
      <div class="channel-card" 
           data-username="${channel.username.toLowerCase()}" 
           data-channel-id="${channel.channelId.toLowerCase()}">
        <div class="channel-header">
          <div class="channel-name">@${channel.username}</div>
          <button class="danger" onclick="removeChannel('${channel.id}')">Remove</button>
        </div>
        <div class="channel-info">
          Channel ID: ${channel.channelId}<br>
          Added: ${DateFormat('MMM dd, yyyy').format(channel.addedAt)}
        </div>
        <button onclick="fetchChannelDetails('${channel.channelId}', '$statsId', '$cardId')">Fetch Latest Videos & Stats</button>
        <div id="$cardId" class="video-container"></div>
      </div>
    ''';
  }
}
