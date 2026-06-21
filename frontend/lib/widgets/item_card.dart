import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/wishlist_item.dart';

class ItemCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  const ItemCard({
    super.key,
    required this.item,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == ItemStatus.DONE;

    return Container(
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF1A2A1A) : const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
        border: isDone
            ? Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImageArea(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isDone ? const Color(0xFF888888) : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF888888),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                              : const Color(0xFF535353).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isDone ? 'DONE' : 'WANTED',
                          style: TextStyle(
                            color: isDone ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isDone ? Icons.check_circle : Icons.check_circle_outline,
                        color: isDone ? const Color(0xFF1DB954) : const Color(0xFF535353),
                        size: 22,
                      ),
                      onPressed: onToggleStatus,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: isDone ? 'Mark as wanted' : 'Mark as done',
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFF535353), size: 20),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete item',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        ApiConfig.resolveImageUrl(item.imageUrl!),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => _placeholder(Icons.image_not_supported_outlined),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _loadingPlaceholder(),
      );
    }

    // Tappable link area — shows OG preview image if available
    if (item.externalUrl != null && item.externalUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openUrl(item.externalUrl!),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.linkPreviewImageUrl != null)
              Image.network(
                item.linkPreviewImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => _linkFallback(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _loadingPlaceholder(),
              )
            else
              _linkFallback(),
            // Bottom gradient bar with domain label
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: Color(0xFF1DB954), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _extractDomain(item.externalUrl!),
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _placeholder(Icons.photo_outlined);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _placeholder(IconData icon, {String? label}) {
    return Container(
      color: const Color(0xFF282828),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF535353), size: 28),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF535353), fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _linkFallback() => Container(
        color: const Color(0xFF282828),
        child: const Center(
          child: Icon(Icons.link_rounded, color: Color(0xFF1DB954), size: 28),
        ),
      );

  String _extractDomain(String url) {
    try {
      String host = Uri.parse(url).host;
      if (host.startsWith('www.')) host = host.substring(4);
      return host.isEmpty ? url : host;
    } catch (_) {
      return url;
    }
  }

  Widget _loadingPlaceholder() => Container(color: const Color(0xFF282828));
}
