import '../models/channel.dart';
import '../models/video.dart';
import 'package:intl/intl.dart';

class DashboardView {
  static String render(List<Channel> channels) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>YouTube Channel Monitor</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        h1 { color: #FF0000; margin-bottom: 30px; font-size: 32px; }
        .header {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .add-channel-form {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }
        input {
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            flex: 1;
        }
        button {
            padding: 12px 24px;
            background: #FF0000;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: background 0.2s;
        }
        button:hover { background: #CC0000; }
        button.secondary {
            background: #065fd4;
        }
        button.secondary:hover { background: #0552b5; }
        button.danger {
            background: #dc3545;
            padding: 8px 16px;
            font-size: 12px;
        }
        button.danger:hover { background: #c82333; }
        .channels-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
        }
        .channel-card {
            background: white;
            padding: 24px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .channel-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
        }
        .channel-name {
            font-size: 18px;
            font-weight: 600;
            color: #030303;
        }
        .channel-info {
            font-size: 12px;
            color: #606060;
            margin-bottom: 16px;
        }
        .video-container {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #e0e0e0;
        }
        .video-item {
            display: flex;
            gap: 12px;
            margin-bottom: 16px;
            padding-bottom: 16px;
            border-bottom: 1px solid #f0f0f0;
        }
        .video-item:last-child { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
        .video-thumbnail {
            width: 120px;
            height: 68px;
            object-fit: cover;
            border-radius: 8px;
            flex-shrink: 0;
        }
        .video-details {
            flex: 1;
            min-width: 0;
        }
        .video-title {
            font-size: 14px;
            font-weight: 500;
            color: #030303;
            margin-bottom: 4px;
            overflow: hidden;
            text-overflow: ellipsis;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
        }
        .video-stats {
            font-size: 12px;
            color: #606060;
        }
        .loading {
            text-align: center;
            padding: 40px;
            color: #606060;
        }
        .report-section {
            background: white;
            padding: 30px;
            border-radius: 12px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-top: 30px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .stat-card {
            padding: 20px;
            background: #f9f9f9;
            border-radius: 8px;
            text-align: center;
        }
        .stat-value {
            font-size: 32px;
            font-weight: 700;
            color: #FF0000;
        }
        .stat-label {
            font-size: 14px;
            color: #606060;
            margin-top: 8px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📺 YouTube Channel Monitor</h1>
            <div class="add-channel-form">
                <input type="text" id="usernameInput" placeholder="Enter YouTube username or channel ID" />
                <button onclick="addChannel()">Add Channel</button>
                <button class="secondary" onclick="fetchAllReports()">Generate All Reports</button>
            </div>
        </div>

        <div id="reportSection" class="report-section" style="display:none;">
            <h2>📊 Combined Report</h2>
            <div id="reportContent" class="stats-grid"></div>
        </div>

        <div class="channels-grid" id="channelsGrid">
            ${channels.reversed.map((channel) => _renderChannelCard(channel)).join()}
        </div>
    </div>

    <script>
        async function addChannel() {
            const username = document.getElementById('usernameInput').value.trim();
            if (!username) {
                alert('Please enter a username or channel ID');
                return;
            }

            try {
                const response = await fetch('/api/channels/add', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username })
                });

                if (response.ok) {
                    location.reload();
                } else {
                    const error = await response.text();
                    alert('Error: ' + error);
                }
            } catch (e) {
                alert('Failed to add channel: ' + e.message);
            }
        }

        async function removeChannel(id) {
            if (!confirm('Remove this channel?')) return;

            try {
                await fetch(\`/api/channels/\${id}\`, { method: 'DELETE' });
                location.reload();
            } catch (e) {
                alert('Failed to remove channel: ' + e.message);
            }
        }

        async function fetchVideos(channelId, cardId) {
            const container = document.getElementById(cardId);
            container.innerHTML = '<div class="loading">Loading videos...</div>';

            try {
                const response = await fetch(\`/api/channels/\${channelId}/videos\`);
                const videos = await response.json();

                if (videos.length === 0) {
                    container.innerHTML = '<div class="loading">No videos found</div>';
                    return;
                }

                container.innerHTML = videos.map(video => \`
                    <div class="video-item">
                        <img src="\${video.thumbnailUrl}" class="video-thumbnail" alt="Thumbnail" />
                        <div class="video-details">
                            <div class="video-title">\${video.title}</div>
                            <div class="video-stats">
                                👁️ \${formatNumber(video.viewCount)} views • 
                                👍 \${formatNumber(video.likeCount)} likes • 
                                📅 \${formatDate(video.publishedAt)}
                            </div>
                        </div>
                    </div>
                \`).join('');
            } catch (e) {
                container.innerHTML = '<div class="loading">Error loading videos</div>';
            }
        }

        async function fetchAllReports() {
            const reportSection = document.getElementById('reportSection');
            const reportContent = document.getElementById('reportContent');
            
            reportSection.style.display = 'block';
            reportContent.innerHTML = '<div class="loading">Generating report...</div>';

            try {
                const response = await fetch('/api/reports/all');
                const report = await response.json();

                reportContent.innerHTML = \`
                    <div class="stat-card">
                        <div class="stat-value">\${report.totalChannels}</div>
                        <div class="stat-label">Total Channels</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\${report.totalVideos}</div>
                        <div class="stat-label">Total Videos</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\${formatNumber(report.totalViews)}</div>
                        <div class="stat-label">Total Views</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">\${formatNumber(report.totalLikes)}</div>
                        <div class="stat-label">Total Likes</div>
                    </div>
                \`;
            } catch (e) {
                reportContent.innerHTML = '<div class="loading">Error generating report</div>';
            }
        }

        function formatNumber(num) {
            if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
            if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
            return num.toString();
        }

        function formatDate(dateStr) {
            const date = new Date(dateStr);
            const now = new Date();
            const diffMs = now - date;
            const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
            
            if (diffDays === 0) return 'Today';
            if (diffDays === 1) return 'Yesterday';
            if (diffDays < 7) return diffDays + ' days ago';
            if (diffDays < 30) return Math.floor(diffDays / 7) + ' weeks ago';
            if (diffDays < 365) return Math.floor(diffDays / 30) + ' months ago';
            return Math.floor(diffDays / 365) + ' years ago';
        }
    </script>
</body>
</html>
    ''';
  }

  static String _renderChannelCard(Channel channel) {
    final cardId = 'videos-${channel.id}';
    return '''
      <div class="channel-card">
        <div class="channel-header">
          <div class="channel-name">@${channel.username}</div>
          <button class="danger" onclick="removeChannel('${channel.id}')">Remove</button>
        </div>
        <div class="channel-info">
          Channel ID: ${channel.channelId}<br>
          Added: ${DateFormat('MMM dd, yyyy').format(channel.addedAt)}
        </div>
        <button onclick="fetchVideos('${channel.channelId}', '$cardId')">Fetch Latest Videos</button>
        <div id="$cardId" class="video-container"></div>
      </div>
    ''';
  }
}
