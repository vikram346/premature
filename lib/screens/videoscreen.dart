import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../models/video.dart';
import '../services/api_service.dart';

class VideoScreen extends StatefulWidget {
  final Video video;

  const VideoScreen({super.key, required this.video});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final ApiService apiService = ApiService();

  late Future<Map<String, dynamic>> embedFuture;

  @override
  void initState() {
    super.initState();
    embedFuture = apiService.getVideoEmbed(widget.video.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text('Now Playing'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FutureBuilder<Map<String, dynamic>>(
                future: embedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Unable to load this video.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final playerUrl =
                      'https://adultembed.com/player/embed/${widget.video.id}/';
                  // print('Video ID: ${widget.video.id}');
                  // print('Player URL: $playerUrl');
                  if (playerUrl == null || playerUrl.isEmpty) {
                    return const Center(
                      child: Text(
                        'Player URL unavailable.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return HtmlElementView.fromTagName(
                    tagName: 'iframe',
                    onElementCreated: (element) {
                      final iframe = element as web.HTMLIFrameElement;

                      iframe
                        ..src = playerUrl
                        ..allow = 'autoplay; fullscreen; picture-in-picture'
                        ..allowFullscreen = true
                        ..style.width = '100%'
                        ..style.height = '100%'
                        ..style.border = 'none';
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${widget.video.views} views • ${widget.video.duration}',
                    style: const TextStyle(color: Colors.white54),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.video.description.isEmpty
                        ? 'No description available'
                        : widget.video.description,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
