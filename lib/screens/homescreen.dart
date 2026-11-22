
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/video.dart';
import '../services/api_service.dart';
import '../widgets/video_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final ApiService apiService = ApiService();

  Timer? _searchDebounce;

  List<Video> videos = [];

  int currentPage = 1;

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasNextPage = true;

  String searchQuery = '';
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    loadVideos();

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      if (scrollController.position.extentAfter < 400 &&
          !isLoading &&
          !isLoadingMore &&
          hasNextPage) {
        loadMoreVideos();
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () {
        searchQuery = value.trim();
        loadVideos();
      },
    );
  }

  Future<void> loadVideos() async {
    setState(() {
      isLoading = true;
      isLoadingMore = false;
      errorMessage = null;
      currentPage = 1;
      hasNextPage = true;
    });

    try {
      final result = await apiService.getVideos(
        page: 1,
        query: searchQuery,
      );

      if (!mounted) return;

      setState(() {
        videos = result.videos;
        hasNextPage = result.hasNextPage;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> loadMoreVideos() async {
    if (isLoadingMore || !hasNextPage || isLoading) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final nextPage = currentPage + 1;

      final result = await apiService.getVideos(
        page: nextPage,
        query: searchQuery,
      );

      if (!mounted) return;

      setState(() {
        videos.addAll(result.videos);
        currentPage = nextPage;
        hasNextPage = result.hasNextPage;
        isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoadingMore = false;
      });

      debugPrint('Failed to load more videos: $error');
    }
  }

  Widget _buildVideoContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.redAccent,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 45,
            ),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadVideos,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Text(
          searchQuery.isEmpty
              ? 'No videos available.'
              : 'No matching videos found.',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width < 600
            ? 2
            : width < 1000
                ? 3
                : 4;

        const horizontalPadding = 24.0;
        const spacing = 10.0;

        final cardWidth = (width -
                horizontalPadding -
                spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        final cardHeight = (cardWidth * 9 / 16) + 82;

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          physics: const ClampingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 8,
            mainAxisExtent: cardHeight,
          ),
          itemCount: videos.length + (isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == videos.length) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.redAccent,
                ),
              );
            }

            return VideoCard(video: videos[index]);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Text(
                    'PREMATURE',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Home',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search videos...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white54,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF202020),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  searchQuery.isEmpty
                      ? 'Discover Videos'
                      : 'Search Results',
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildVideoContent(),
            ),
          ],
        ),
      ),
    );
  }
}
