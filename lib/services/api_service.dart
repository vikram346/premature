
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/video_page.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  
Future<VideoPage> getVideos({
  int page = 1,
  int pageSize = 20,
  String query = '',
}) async {
  final parameters = <String, String>{
    'page': page.toString(),
    'page_size': pageSize.toString(),
  };

  if (query.trim().isNotEmpty) {
    parameters['q'] = query.trim();
  }

  final url = Uri.parse('$baseUrl/videos/').replace(
    queryParameters: parameters,
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    return VideoPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  throw Exception('Failed to load videos: ${response.statusCode}');
}


  Future<Map<String, dynamic>> getVideoStreams(int videoId) async {
    final url = Uri.parse('$baseUrl/videos/$videoId/streams');

    final response = await http.get(url).timeout(
      const Duration(seconds: 30),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to load video streams: ${response.statusCode} ${response.body}',
    );
  }
}
