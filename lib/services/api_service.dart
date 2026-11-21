
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/video_page.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8000',
);

  Future<VideoPage> getVideos({
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse('$baseUrl/videos/').replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );

    return _fetchPage(url);
  }

  Future<VideoPage> searchVideos({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    final url = Uri.parse('$baseUrl/videos/search').replace(
      queryParameters: {
        'q': query,
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
    );

    return _fetchPage(url);
  }

  Future<VideoPage> _fetchPage(Uri url) async {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return VideoPage.fromJson(data);
    }

    throw Exception(
      'Failed to load videos: ${response.statusCode}',
    );
  }

  Future<Map<String, dynamic>> getVideoDetails(int videoId) async {
  final url = Uri.parse('$baseUrl/videos/$videoId');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  throw Exception(
    'Failed to load video details: ${response.statusCode}',
  );
}

Future<Map<String, dynamic>> getVideoEmbed(int videoId) async {
  final url = Uri.parse('$baseUrl/videos/$videoId/embed');

  final response = await http.post(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  throw Exception('Failed to load video player: ${response.statusCode}');
}
}
