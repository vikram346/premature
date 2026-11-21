import 'package:flutter/material.dart';

import '../models/video.dart';
import '../screens/videoscreen.dart';
import 'package:web/web.dart' as web;

class VideoCard extends StatelessWidget {
  final Video video;

  const VideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // print('CARD CLICKED: ${video.title}');

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VideoScreen(video: video)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: HtmlElementView.fromTagName(
    tagName: 'img',
    onElementCreated: (element) {
      final image = element as web.HTMLImageElement;

      image
        ..src = video.thumbnail
        ..alt = video.title
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.pointerEvents = 'none';
    },
  ),
),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${video.views} views • ${video.duration}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
