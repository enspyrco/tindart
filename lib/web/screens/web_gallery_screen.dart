import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/services/artwork_service.dart';
import 'package:tindart/theme/web_theme.dart';
import 'package:tindart/utils/breakpoints.dart';
import 'package:tindart/widgets/artwork_grid.dart';
import 'package:tindart/web/widgets/breadcrumb_nav.dart';
import 'package:tindart/web/widgets/web_header.dart';

class WebGalleryScreen extends StatefulWidget {
  const WebGalleryScreen({super.key});

  @override
  State<WebGalleryScreen> createState() => _WebGalleryScreenState();
}

class _WebGalleryScreenState extends State<WebGalleryScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final ScrollController _scrollController = ScrollController();
  final List<Artwork> _artworks = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadArtworks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);

    final artworks = await _artworkService.getPaginatedArtworks(
      page: _currentPage,
      limit: _pageSize,
    );

    setState(() {
      _artworks.addAll(artworks);
      _isLoading = false;
      _hasMore = artworks.length == _pageSize;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    await _loadArtworks();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = getDeviceType(context) == DeviceType.mobile;
    final horizontalPadding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: WebColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebHeader(currentRoute: '/gallery'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: const BreadcrumbNav(
              items: [
                BreadcrumbItem(label: 'Home', route: '/'),
                BreadcrumbItem(label: 'Gallery'),
              ],
            ),
          ),
          Expanded(
            child: _artworks.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ArtworkGrid(
                    artworks: _artworks,
                    scrollController: _scrollController,
                    isLoading: _isLoading,
                    onArtworkTap: (artwork) {
                      context.push('/artwork/${artwork.docId}');
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
