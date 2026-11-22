
class Video {
  final int? id;
  final String title;
  final String thumbnail;
  final String duration;
  final String views;
  final String description;
  final String embedUrl;

  const Video({
    this.id,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.views,
    required this.description,
    this.embedUrl = '',
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final poster = json['poster'] is Map
    ? json['poster'] as Map<String, dynamic>
    : <String, dynamic>{};

return Video(
  id: json['id'] as int?,
  title: json['title']?.toString() ?? 'Untitled',
  thumbnail: poster['local_url']?.toString() ?? '',
  duration: json['duration_formatted']?.toString() ?? 'Unknown',
  views: json['views']?.toString() ?? '0',
  description: json['description']?.toString() ?? '',
  embedUrl: json['embed_url']?.toString() ?? '',
);
  }
}
