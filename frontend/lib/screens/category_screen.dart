import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/category.dart';
import '../models/wishlist_item.dart';
import '../services/wishlist_service.dart';
import '../widgets/item_row.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final WishlistService _service = WishlistService();

  List<WishlistItem> _items = [];
  bool _loading = true;
  String? _error;

  // null means "show all"
  ItemStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getItems(
        category: widget.category.slug,
        status: _filterStatus?.name,
      );
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load items. Is the server running?';
        _loading = false;
      });
    }
  }

  Future<void> _toggleStatus(WishlistItem item) async {
    final newStatus =
        item.status == ItemStatus.WANTED ? ItemStatus.DONE : ItemStatus.WANTED;
    try {
      final updated = await _service.updateStatus(item.id!, newStatus);
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) _items[index] = updated;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update status')),
        );
      }
    }
  }

  Future<void> _deleteItem(WishlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Delete item?',
            style: TextStyle(color: Colors.white)),
        content: Text('Remove "${item.title}" from your list?',
            style: const TextStyle(color: Color(0xFFB3B3B3))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFCF6679))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteItem(item.id!);
        setState(() => _items.removeWhere((i) => i.id == item.id));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not delete item')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text('${widget.category.icon ?? ''} ${widget.category.name}'),
        actions: [
          PopupMenuButton<ItemStatus?>(
            icon: Icon(
              Icons.filter_list,
              color: _filterStatus != null
                  ? const Color(0xFF1DB954)
                  : Colors.white,
            ),
            color: const Color(0xFF282828),
            onSelected: (status) {
              setState(() => _filterStatus = status);
              _loadItems();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('All items',
                    style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: ItemStatus.WANTED,
                child: Text('Wanted only',
                    style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: ItemStatus.DONE,
                child: Text('Done only',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // result == true means a new item was saved; reload the list
          final result = await context.push<bool>(
              '/category/${widget.category.slug}/add',
              extra: widget.category);
          if (result == true) _loadItems();
        },
        backgroundColor: const Color(0xFF1DB954),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Color(0xFF535353), size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFFB3B3B3))),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadItems, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.category.icon ?? '📋',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing here yet!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add your first item',
              style: TextStyle(color: Color(0xFFB3B3B3)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      color: const Color(0xFF1DB954),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
