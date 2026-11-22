
import 'video.dart';

class VideoPage {
  final List<Video> videos;
  final bool hasNextPage;

  const VideoPage({
    required this.videos,
    required this.hasNextPage,
  });

  factory VideoPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];

    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return VideoPage(
      videos: items
          .whereType<Map<String, dynamic>>()
          .map((item) => Video.fromJson(item))
          .toList(),
      hasNextPage: pagination['has_next'] == true,
    );
  }
}
