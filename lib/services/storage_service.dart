import 'dart:io';
import 'dart:convert';
import '../models/channel.dart';

class StorageService {
  final String filePath;

  StorageService({this.filePath = 'data/channels.json'});

  /// Load channels from JSON file
  Future<List<Channel>> loadChannels() async {
    final file = File(filePath);

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]');
      return [];
    }

    final content = await file.readAsString();
    final List<dynamic> jsonList = json.decode(content);

    return jsonList.map((json) => Channel.fromJson(json)).toList();
  }

  /// Get existing channel by username or channel ID
  Future<Channel?> getExistingChannel(String username, String channelId) async {
    final channels = await loadChannels();

    try {
      return channels.firstWhere((channel) =>
          channel.username.toLowerCase() == username.toLowerCase() ||
          channel.channelId == channelId);
    } catch (e) {
      return null;
    }
  }

  /// Save channels to JSON file
  Future<void> saveChannels(List<Channel> channels) async {
    final file = File(filePath);
    final jsonList = channels.map((c) => c.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  /// Add a new channel
  Future<Channel> addChannel(String username, String channelId) async {
    final channels = await loadChannels();

    // Check if channel already exists
    final Channel? existing = await getExistingChannel(username, channelId);

    ///
    if (existing != null) {
      return existing;
    }

    final newChannel = Channel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      channelId: channelId,
      addedAt: DateTime.now(),
    );

    ///
    channels.add(newChannel);
    await saveChannels(channels);

    return newChannel;
  }

  /// Remove a channel
  Future<void> removeChannel(String id) async {
    final channels = await loadChannels();
    channels.removeWhere((c) => c.id == id);
    await saveChannels(channels);
  }
}
