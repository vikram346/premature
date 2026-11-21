
class Video {
  final int? id;
  final String title;
  final String thumbnail;
  final String duration;
  final String views;
  final String description;

  const Video({
    this.id,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.views,
    required this.description,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as int?,
      title: json['title']?.toString() ?? 'Untitled',
      thumbnail: json['thumbnail']?.toString() ?? '',
      duration: json['duration']?.toString() ?? 'Unknown',
      views: json['views']?.toString() ?? '0',
      description: json['description']?.toString() ?? '',
    );
  }
}
