
import 'dart:ui_web' as ui_web;

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
  static int _counter = 0;

  final ApiService _api = ApiService();

  String? _viewType;
  String? _error;
  String _selectedQuality = '720p';
  bool _loading = true;

  Map<String, dynamic> _sources = {};
  web.HTMLVideoElement? _player;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final id = widget.video.id;

      if (id == null) {
        throw Exception('Video ID is missing');
      }

      final data = await _api.getVideoStreams(id);
      final sources = Map<String, dynamic>.from(data['sources'] ?? {});

      if (sources.isEmpty) {
        throw Exception('No video sources available');
      }

      final quality = sources.containsKey('720p')
          ? '720p'
          : sources.containsKey('480p')
              ? '480p'
              : sources.keys.first;

      final url = sources[quality]?['url']?.toString();

      if (url == null || url.isEmpty) {
        throw Exception('No playable MP4 URL found');
      }

      final viewType = 'video-player-${_counter++}';

      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final player = web.HTMLVideoElement()
          ..src = url
          ..controls = true
          ..autoplay = false
          ..preload = 'metadata'
          ..poster = _posterUrl();

        player.setAttribute('playsinline', '');

        player.style
          ..width = '100%'
          ..height = '100%'
          ..objectFit = 'contain'
          ..backgroundColor = 'black';

        _player = player;

        return player;
      });

      if (!mounted) return;

      setState(() {
        _sources = sources;
        _selectedQuality = quality;
        _viewType = viewType;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _posterUrl() {
    final thumbnail = widget.video.thumbnail;

    if (thumbnail.isEmpty) return '';

    return '${ApiService.baseUrl}/images/proxy?url=${Uri.encodeComponent(thumbnail)}';
  }

  void _changeQuality(String quality) {
    final url = _sources[quality]?['url']?.toString();

    if (url == null || url.isEmpty) return;

    final player = _player;
    if (player == null) return;

    setState(() {
      _selectedQuality = quality;
    });

    player.pause();
    player.src = url;
    player.load();
  }

  @override
  void dispose() {
    _player?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        foregroundColor: Colors.white,
        title: const Text('PREMATURE'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildPlayer(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (_sources.isNotEmpty)
                    Row(
                      children: [
                        const Text(
                          'Quality',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _selectedQuality,
                          dropdownColor: const Color(0xFF252525),
                          style: const TextStyle(color: Colors.white),
                          items: _sources.keys.map((quality) {
                            return DropdownMenuItem<String>(
                              value: quality,
                              child: Text(quality),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _changeQuality(value);
                            }
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '${video.duration} • ${video.views} views',
                    style: const TextStyle(color: Colors.white54),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'About this video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    video.description.isEmpty
                        ? 'No description available.'
                        : video.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_loading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildPoster(),
          const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          ),
        ],
      );
    }

    if (_error != null || _viewType == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildPoster(),
          Container(color: Colors.black.withOpacity(0.65)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white54,
                    size: 45,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Unable to load video',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  TextButton(
                    onPressed: _loadStreams,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return HtmlElementView(viewType: _viewType!);
  }

  Widget _buildPoster() {
    final poster = _posterUrl();

    if (poster.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }

    return Image.network(
      poster,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: Colors.black);
      },
    );
  }
}
