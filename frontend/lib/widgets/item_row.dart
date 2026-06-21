import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/wishlist_item.dart';

class ItemRow extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const ItemRow({
    super.key,
    required this.item,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == ItemStatus.DONE;

    return Container(
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF1A2A1A) : const Color(0xFF181818),
        borderRadius: BorderRadius.circular(8),
        border: isDone
            ? Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: item.externalUrl != null
                ? () async {
                    final uri = Uri.tryParse(item.externalUrl!);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                : null,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: SizedBox(width: 80, height: 80, child: _buildThumb()),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${item.category.icon ?? ''} ${item.category.name}',
                        style: const TextStyle(
                            color: Color(0xFFB3B3B3), fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      if (item.createdAt != null)
                        Text(
                          _formatDate(item.createdAt!),
                          style: const TextStyle(
                              color: Color(0xFF535353), fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                          : const Color(0xFF535353).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDone ? 'DONE' : 'WANTED',
                      style: TextStyle(
                        color: isDone
                            ? const Color(0xFF1DB954)
                            : const Color(0xFFB3B3B3),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  isDone ? Icons.check_circle : Icons.check_circle_outline,
                  color: isDone
                      ? const Color(0xFF1DB954)
                      : const Color(0xFF535353),
                  size: 20,
                ),
                onPressed: onToggleStatus,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFF535353), size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildThumb() {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        ApiConfig.resolveImageUrl(item.imageUrl!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _iconBox(Icons.image_not_supported_outlined),
      );
    }
    if (item.externalUrl != null && item.externalUrl!.isNotEmpty) {
      if (item.linkPreviewImageUrl != null) {
        return Image.network(
          item.linkPreviewImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _iconBox(Icons.link_rounded, color: const Color(0xFF1DB954)),
        );
      }
      return _iconBox(Icons.link_rounded, color: const Color(0xFF1DB954));
    }
    return _iconBox(Icons.photo_outlined);
  }

  Widget _iconBox(IconData icon, {Color color = const Color(0xFF535353)}) {
    return Container(
      color: const Color(0xFF282828),
      child: Center(child: Icon(icon, color: color, size: 24)),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
