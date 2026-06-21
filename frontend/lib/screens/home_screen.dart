import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../services/wishlist_service.dart';
import 'feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WishlistService _service = WishlistService();
  List<Category> _categories = [];
  bool _loading = true;
  int _tab = 0; // 0 = Feed (main), 1 = Categories
  int _feedRefreshKey = 0; // incrementing forces FeedScreen to reload

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _service.getCategories();
      setState(() { _categories = cats; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addItemFromFeed() async {
    if (_categories.isEmpty) return;
    final result = await context.push<bool>('/add', extra: _categories);
    if (result == true) setState(() => _feedRefreshKey++);
  }

  static const _emojiOptions = [
    '🎵', '🎮', '🏋️', '📚', '✈️', '🍕', '🎬', '🛍️',
    '🌿', '🐾', '💊', '🎨', '🏡', '⚽', '🎸', '💻',
    '🧁', '🧳', '🎁', '💄', '🪴', '🏖️', '🎯', '🔧',
  ];

  Future<void> _showCreateCategoryDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    String? error;
    String? selectedEmoji;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF282828),
          title: const Text('New category', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Music, Travel...',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'ICON',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _emojiOptions.map((emoji) {
                    final selected = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedEmoji = emoji),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1DB954).withValues(alpha: 0.25)
                              : const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1DB954)
                                : const Color(0xFF535353),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedEmoji == null && error != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Pick an icon',
                    style: TextStyle(color: Color(0xFFCF6679), fontSize: 12),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Color(0xFFCF6679), fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final nameValid = formKey.currentState!.validate();
                      if (!nameValid || selectedEmoji == null) {
                        setDialogState(() => error = selectedEmoji == null ? 'Pick an icon above' : null);
                        return;
                      }
                      setDialogState(() { saving = true; error = null; });
                      try {
                        final cat = await _service.createCategory(
                          nameController.text.trim(),
                          selectedEmoji!,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        setState(() => _categories.add(cat));
                      } on DioException catch (e) {
                        final msg = e.response?.data is Map
                            ? (e.response!.data['error'] as String?)
                            : null;
                        setDialogState(() {
                          saving = false;
                          error = msg ?? 'Could not create category (${e.response?.statusCode ?? 'no response'})';
                        });
                      } catch (e) {
                        setDialogState(() {
                          saving = false;
                          error = e.toString();
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.username ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mangetout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Partner',
            onPressed: () async {
              final linked = await context.push<bool>('/invite');
              if (linked == true) setState(() => _feedRefreshKey++);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: _AvatarChip(username: username, avatarUrl: auth.avatarUrl),
            ),
          ),
        ],
      ),

      body: _tab == 0
          ? FeedScreen(key: ValueKey(_feedRefreshKey))
          : _buildCategoriesTab(username),

      floatingActionButton: FloatingActionButton(
        onPressed: _tab == 0 ? _addItemFromFeed : _showCreateCategoryDialog,
        backgroundColor: const Color(0xFF1DB954),
        foregroundColor: Colors.black,
        tooltip: _tab == 0 ? 'Add item' : 'New category',
        child: Icon(_tab == 0 ? Icons.add : Icons.auto_awesome),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.black,
        indicatorColor: const Color(0xFF1DB954).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list, color: Color(0xFF1DB954)),
            label: 'All items',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: Color(0xFF1DB954)),
            label: 'Categories',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(String username) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)));
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_timeOfDay()},',
                  style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'YOUR WISHLISTS',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) =>
                _CategoryCard(category: _categories[index]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _CategoryCard extends StatefulWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  // Colours for the 6 default categories; custom ones get a neutral grey
  static const Map<String, Color> _gradients = {
    'recipes':    Color(0xFFE13300),
    'places':     Color(0xFF0D73EC),
    'movies':     Color(0xFF8D67AB),
    'furniture':  Color(0xFFE8115B),
    'books':      Color(0xFFF59B23),
    'activities': Color(0xFF1DB954),
  };

  @override
  Widget build(BuildContext context) {
    final baseColor = _gradients[widget.category.slug] ?? const Color(0xFF535353);
    final darkColor = _darken(baseColor, 0.25);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(
          '/category/${widget.category.slug}',
          extra: widget.category,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF282828) : const Color(0xFF181818),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.6 : 0.3),
                blurRadius: _hovered ? 20 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [baseColor, darkColor],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.category.icon ?? '📋',
                        style: const TextStyle(fontSize: 52),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Wishlist',
                          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}

class _AvatarChip extends StatelessWidget {
  final String username;
  final String? avatarUrl;

  const _AvatarChip({required this.username, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(
          avatarUrl!.replaceFirst(RegExp(r'https?://[^/]+'), 'http://localhost:8080'),
        ),
        backgroundColor: const Color(0xFF535353),
      );
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF535353),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
