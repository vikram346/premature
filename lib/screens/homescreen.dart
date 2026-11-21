
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

  List<Video> videos = [];

  String searchQuery = '';

  int currentPage = 1;
  int _requestVersion = 0;

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasNextPage = true;

  String? errorMessage;

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    loadVideos();

    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 300 &&
          !isLoading &&
          !isLoadingMore &&
          hasNextPage) {
        loadMoreVideos();
      }
    });
  }

  Future<void> loadVideos({String? query}) async {
    final requestVersion = ++_requestVersion;
    final currentQuery = (query ?? searchQuery).trim();

    setState(() {
      isLoading = true;
      isLoadingMore = false;
      errorMessage = null;
      currentPage = 1;
      hasNextPage = true;
      videos = [];
    });

    try {
      final result = currentQuery.isEmpty
          ? await apiService.getVideos(page: 1)
          : await apiService.searchVideos(
              query: currentQuery,
              page: 1,
            );

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        videos = result.videos;
        hasNextPage = result.hasNextPage;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> loadMoreVideos() async {
    if (isLoadingMore || !hasNextPage || isLoading) return;

    final requestVersion = _requestVersion;
    final currentQuery = searchQuery.trim();
    final nextPage = currentPage + 1;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final result = currentQuery.isEmpty
          ? await apiService.getVideos(page: nextPage)
          : await apiService.searchVideos(
              query: currentQuery,
              page: nextPage,
            );

      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        videos.addAll(result.videos);
        currentPage = nextPage;
        hasNextPage = result.hasNextPage;
        isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;

      setState(() {
        isLoadingMore = false;
      });

      debugPrint('Failed to load more videos: $error');
    }
  }

  void onSearchChanged(String value) {
    searchQuery = value;

    // Invalidate any older requests.
    _requestVersion++;

    _searchDebounce?.cancel();

    setState(() {
      isLoading = true;
      isLoadingMore = false;
      errorMessage = null;
      videos = [];
      currentPage = 1;
      hasNextPage = true;
    });

    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () {
        loadVideos(query: value);
      },
    );
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
              style: const TextStyle(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => loadVideos(query: searchQuery),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Text(
          searchQuery.trim().isEmpty
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

        final crossAxisCount = width >= 1100
            ? 4
            : width >= 700
                ? 3
                : 2;

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: videos.length + (isLoadingMore ? 1 : 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 24,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            if (index >= videos.length) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.redAccent,
                ),
              );
            }

            return VideoCard(
              video: videos[index],
            );
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
            // Top navigation
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
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
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: searchController,
                style: const TextStyle(
                  color: Colors.white,
                ),
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white54,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF202020),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Section heading
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Discover Videos',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 29,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Video grid
            Expanded(
              child: _buildVideoContent(),
            ),
          ],
        ),
      ),
    );
  }
}
