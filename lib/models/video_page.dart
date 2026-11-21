import 'video.dart';

class VideoPage {
  final List<Video> videos;
  final bool hasNextPage;

  const VideoPage({
    required this.videos,
    required this.hasNextPage,
  });

  factory VideoPage.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>;

    return VideoPage(
      videos: results
          .map((item) => Video.fromJson(item as Map<String, dynamic>))
          .toList(),
      hasNextPage: json['next'] != null,
    );
  }
}