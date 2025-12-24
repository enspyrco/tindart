import 'package:flutter/material.dart';
import 'package:tindart/services/artwork_service.dart';
import 'package:tindart/utils/breakpoints.dart';
import 'package:tindart/widgets/artwork_card.dart';

class ArtworkGrid extends StatelessWidget {
  final List<Artwork> artworks;
  final void Function(Artwork artwork)? onArtworkTap;
  final ScrollController? scrollController;
  final bool isLoading;

  const ArtworkGrid({
    super.key,
    required this.artworks,
    this.onArtworkTap,
    this.scrollController,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final columns = getGridColumns(context);
    final spacing = getGridSpacing(context);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(spacing),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final artwork = artworks[index];
                return ArtworkCard(
                  artwork: artwork,
                  onTap: () => onArtworkTap?.call(artwork),
                );
              },
              childCount: artworks.length,
            ),
          ),
        ),
        if (isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
