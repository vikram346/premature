import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/video_page.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

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

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return VideoPage.fromJson(data);
    } else {
      throw Exception(
        'Failed to load videos: ${response.statusCode}',
      );
    }
  }
}