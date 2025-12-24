import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tindart/comments/comments_widget.dart';
import 'package:tindart/services/artwork_service.dart';
import 'package:tindart/theme/web_theme.dart';
import 'package:tindart/utils/breakpoints.dart';
import 'package:tindart/widgets/like_dislike_buttons.dart';
import 'package:tindart/web/widgets/breadcrumb_nav.dart';
import 'package:tindart/web/widgets/web_header.dart';

class WebArtworkDetailScreen extends StatefulWidget {
  final String artworkId;

  const WebArtworkDetailScreen({super.key, required this.artworkId});

  @override
  State<WebArtworkDetailScreen> createState() => _WebArtworkDetailScreenState();
}

class _WebArtworkDetailScreenState extends State<WebArtworkDetailScreen> {
  final ArtworkService _artworkService = ArtworkService();
  Artwork? _artwork;
  bool _isLoading = true;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    final artwork = await _artworkService.getArtworkById(widget.artworkId);
    final isLiked = await _artworkService.isArtworkLiked(widget.artworkId);

    setState(() {
      _artwork = artwork;
      _isLiked = isLiked;
      _isLoading = false;
    });
  }

  Future<void> _handleLike() async {
    if (_artwork == null) return;

    await _artworkService.savePreference(
      docId: _artwork!.docId,
      field: 'liked',
    );

    setState(() => _isLiked = true);
  }

  Future<void> _handleDislike() async {
    if (_artwork == null) return;

    await _artworkService.savePreference(
      docId: _artwork!.docId,
      field: 'disliked',
    );

    if (mounted) {
      context.go('/gallery');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isDesktop =
        deviceType == DeviceType.desktop || deviceType == DeviceType.widescreen;

    return Scaffold(
      backgroundColor: WebColors.background,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              context.go('/gallery');
            }
          }
        },
        child: Column(
          children: [
            const WebHeader(currentRoute: '/gallery'),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _artwork == null
                      ? const Center(child: Text('Artwork not found'))
                      : isDesktop
                          ? _DesktopLayout(
                              artwork: _artwork!,
                              isLiked: _isLiked,
                              onLike: _handleLike,
                              onDislike: _handleDislike,
                            )
                          : _MobileLayout(
                              artwork: _artwork!,
                              isLiked: _isLiked,
                              onLike: _handleLike,
                              onDislike: _handleDislike,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final Artwork artwork;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _DesktopLayout({
    required this.artwork,
    required this.isLiked,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Image section
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: Center(
              child: Image.network(
                artwork.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Side panel
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: WebColors.surface,
            border: Border(
              left: BorderSide(color: WebColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb and close button
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: BreadcrumbNav(
                        items: [
                          const BreadcrumbItem(label: 'Home', route: '/'),
                          const BreadcrumbItem(
                              label: 'Gallery', route: '/gallery'),
                          BreadcrumbItem(label: artwork.fileName),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.go('/gallery'),
                      tooltip: 'Close (Esc)',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.fileName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: LikeDislikeButtons(
                        isLiked: isLiked,
                        onLike: onLike,
                        onDislike: onDislike,
                        large: true,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Comments
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: CommentsWidget(imageId: artwork.docId),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final Artwork artwork;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const _MobileLayout({
    required this.artwork,
    required this.isLiked,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Back button and breadcrumb
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/gallery'),
              ),
              Expanded(
                child: BreadcrumbNav(
                  items: [
                    const BreadcrumbItem(label: 'Gallery', route: '/gallery'),
                    BreadcrumbItem(label: artwork.fileName),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Image
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: Image.network(
              artwork.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Actions and comments
        Expanded(
          flex: 1,
          child: Container(
            color: WebColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LikeDislikeButtons(
                    isLiked: isLiked,
                    onLike: onLike,
                    onDislike: onDislike,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CommentsWidget(imageId: artwork.docId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
