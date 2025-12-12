import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebDetectionSheet extends StatelessWidget {
  const WebDetectionSheet({required this.data, super.key});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final bestGuessLabels = (data['bestGuessLabels'] as List?) ?? [];
    final webEntities = (data['webEntities'] as List?) ?? [];
    final visuallySimilarImages =
        (data['visuallySimilarImages'] as List?) ?? [];
    final pagesWithMatchingImages =
        (data['pagesWithMatchingImages'] as List?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Web Detection Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (bestGuessLabels.isNotEmpty) ...[
                _buildSectionTitle('Best Guess'),
                ...bestGuessLabels.map((label) => Chip(
                      label: Text(label['label'] ?? ''),
                    )),
                const SizedBox(height: 16),
              ],
              if (webEntities.isNotEmpty) ...[
                _buildSectionTitle('Related Topics'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: webEntities
                      .where((e) => e['description'] != null)
                      .take(10)
                      .map<Widget>((entity) => Chip(
                            label: Text(entity['description'] ?? ''),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (visuallySimilarImages.isNotEmpty) ...[
                _buildSectionTitle('Visually Similar Images'),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: visuallySimilarImages.length.clamp(0, 10),
                    itemBuilder: (context, index) {
                      final url =
                          visuallySimilarImages[index]['url'] as String?;
                      if (url == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _launchUrl(url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (pagesWithMatchingImages.isNotEmpty) ...[
                _buildSectionTitle('Pages with Matching Images'),
                ...pagesWithMatchingImages.take(10).map((page) {
                  final url = page['url'] as String?;
                  final title = page['pageTitle'] as String? ?? url ?? '';
                  if (url == null) return const SizedBox.shrink();
                  return ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap: () => _launchUrl(url),
                  );
                }),
              ],
              if (bestGuessLabels.isEmpty &&
                  webEntities.isEmpty &&
                  visuallySimilarImages.isEmpty &&
                  pagesWithMatchingImages.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No results found'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
