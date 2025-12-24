import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/services/artwork_service.dart';
import 'package:tindart/theme/web_theme.dart';
import 'package:tindart/utils/breakpoints.dart';
import 'package:tindart/widgets/artwork_grid.dart';
import 'package:tindart/web/widgets/breadcrumb_nav.dart';
import 'package:tindart/web/widgets/web_header.dart';

class WebLikedScreen extends StatefulWidget {
  const WebLikedScreen({super.key});

  @override
  State<WebLikedScreen> createState() => _WebLikedScreenState();
}

class _WebLikedScreenState extends State<WebLikedScreen> {
  final ArtworkService _artworkService = ArtworkService();
  List<Artwork> _likedArtworks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedArtworks();
  }

  Future<void> _loadLikedArtworks() async {
    final artworks = await _artworkService.getLikedArtworks();
    setState(() {
      _likedArtworks = artworks;
      _isLoading = false;
    });
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
          const WebHeader(currentRoute: '/liked'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: const BreadcrumbNav(
              items: [
                BreadcrumbItem(label: 'Home', route: '/'),
                BreadcrumbItem(label: 'Liked'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _likedArtworks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_outline,
                              size: 64,
                              color: WebColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No liked artworks yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: WebColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.go('/gallery'),
                              child: const Text('Browse Gallery'),
                            ),
                          ],
                        ),
                      )
                    : ArtworkGrid(
                        artworks: _likedArtworks,
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
