import 'package:flutter/material.dart';
import '../models/wishlist_item.dart';
import '../services/wishlist_service.dart';
import '../widgets/item_row.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final WishlistService _service = WishlistService();
  List<WishlistItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await _service.getItems();
      items.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      setState(() { _items = items; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Could not load items. Is the server running?'; _loading = false; });
    }
  }

  Future<void> _toggleStatus(WishlistItem item) async {
    final newStatus = item.status == ItemStatus.WANTED ? ItemStatus.DONE : ItemStatus.WANTED;
    try {
      final updated = await _service.updateStatus(item.id!, newStatus);
      setState(() {
        final i = _items.indexWhere((x) => x.id == item.id);
        if (i != -1) _items[i] = updated;
      });
    } catch (_) {}
  }

  Future<void> _deleteItem(WishlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Delete item?', style: TextStyle(color: Colors.white)),
        content: Text('Remove "${item.title}"?',
            style: const TextStyle(color: Color(0xFFB3B3B3))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFCF6679))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteItem(item.id!);
      setState(() => _items.removeWhere((x) => x.id == item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off, color: Color(0xFF535353), size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Color(0xFFB3B3B3))),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Retry')),
        ]),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inbox_outlined, color: Color(0xFF535353), size: 48),
          SizedBox(height: 16),
          Text('No items yet. Tap + to add something!',
              style: TextStyle(color: Color(0xFFB3B3B3))),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF1DB954),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, index) {
          final item = _items[index];
          return ItemRow(
            item: item,
            onToggleStatus: () => _toggleStatus(item),
            onDelete: () => _deleteItem(item),
          );
        },
      ),
    );
  }
}
