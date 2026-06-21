import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../models/wishlist_item.dart';
import '../services/wishlist_service.dart';

class AddItemScreen extends StatefulWidget {
  final Category? category;
  final List<Category>? categories;

  const AddItemScreen({super.key, this.category, this.categories})
      : assert(category != null || categories != null,
            'Provide either a pre-selected category or a list to pick from');

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

enum _AttachmentMode { none, link, photo }

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final WishlistService _service = WishlistService();

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();

  _AttachmentMode _attachmentMode = _AttachmentMode.none;
  XFile? _pickedImage;
  bool _saving = false;
  String? _error;

  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        _attachmentMode = _AttachmentMode.photo;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      setState(() => _error = 'Please select a category');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      String? imageUrl;
      String? externalUrl;

      if (_attachmentMode == _AttachmentMode.photo && _pickedImage != null) {
        imageUrl = await _service.uploadImage(_pickedImage!);
      }

      if (_attachmentMode == _AttachmentMode.link) {
        final url = _urlController.text.trim();
        if (url.isNotEmpty) externalUrl = url;
      }

      final newItem = WishlistItem(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        imageUrl: imageUrl,
        externalUrl: externalUrl,
        category: _selectedCategory!,
      );

      await _service.createItem(newItem);

      // context.pop(true) signals CategoryScreen to reload its list
      if (mounted) context.pop(true);
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?['error'] ?? 'Could not save item. Try again.';
        _saving = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Is the server running?';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(false),
        ),
        title: Text(_selectedCategory != null
            ? 'Add to ${_selectedCategory!.name}'
            : 'Add to wishlist'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- CATEGORY PICKER (only when coming from the feed, no pre-selected category) ----
                if (widget.categories != null) ...[
                  _label('Category *'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    dropdownColor: const Color(0xFF282828),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Choose a category'),
                    items: widget.categories!.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text('${cat.icon ?? ''} ${cat.name}'),
                      );
                    }).toList(),
                    onChanged: (cat) => setState(() {
                      _selectedCategory = cat;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                ],

                _label('Title *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Watch Dune, Try the ramen place...',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 20),

                _label('Notes (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Tips, reminders, context...',
                  ),
                ),
                const SizedBox(height: 28),

                _label('Add a reference (optional)'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        icon: Icons.link,
                        label: 'Paste a link',
                        selected: _attachmentMode == _AttachmentMode.link,
                        onTap: () => setState(() {
                          _attachmentMode = _attachmentMode == _AttachmentMode.link
                              ? _AttachmentMode.none
                              : _AttachmentMode.link;
                          _pickedImage = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modeButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Pick a photo',
                        selected: _attachmentMode == _AttachmentMode.photo,
                        onTap: () {
                          if (_attachmentMode == _AttachmentMode.photo) {
                            setState(() {
                              _attachmentMode = _AttachmentMode.none;
                              _pickedImage = null;
                            });
                          } else {
                            _pickImage();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_attachmentMode == _AttachmentMode.link) ...[
                  TextFormField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      hintText: 'https://...',
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (v) {
                      if (_attachmentMode != _AttachmentMode.link) return null;
                      if (v == null || v.trim().isEmpty) return null;
                      if (!v.startsWith('http')) return 'Enter a valid URL starting with http';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_pickedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _pickedImage!.path,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        height: 200,
                        color: const Color(0xFF282828),
                        child: const Center(
                          child: Text('Image selected',
                              style: TextStyle(color: Color(0xFFB3B3B3))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFCF6679), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('SAVE ITEM'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1DB954).withValues(alpha: 0.15)
              : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF1DB954)
                : const Color(0xFF535353),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF1DB954) : const Color(0xFFB3B3B3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
