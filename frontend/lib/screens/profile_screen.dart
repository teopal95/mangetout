import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/wishlist_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WishlistService _service = WishlistService();
  final AuthService _authService = AuthService();
  final _usernameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _email;
  String? _avatarUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _service.getProfile();
      _usernameController.text = data['username'] as String? ?? '';
      setState(() {
        _email     = data['email'] as String?;
        _avatarUrl = data['avatarUrl'] as String?;
        _loading   = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _service.uploadImage(file);
      setState(() { _avatarUrl = url; _uploadingPhoto = false; });
    } catch (_) {
      setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not upload photo.'),
              backgroundColor: Color(0xFFCF6679)),
        );
      }
    }
  }

  Future<void> _save() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      setState(() => _error = 'Username cannot be empty.');
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final updated = await _service.updateProfile(
        username: newUsername,
        avatarUrl: _avatarUrl,
      );
      final resolvedAvatar = updated['avatarUrl'] as String?;

      await _authService.saveUsername(updated['username'] as String);
      await _authService.saveAvatarUrl(resolvedAvatar);

      if (mounted) {
        context.read<AuthProvider>().updateProfile(
          username: updated['username'] as String,
          avatarUrl: resolvedAvatar,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated.'),
            backgroundColor: Color(0xFF1DB954),
          ),
        );
      }
    } catch (e) {
      String msg = 'Could not save changes.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) msg = (data['error'] as String?) ?? msg;
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // ── Avatar ──────────────────────────────────────────
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildAvatar(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1DB954),
                            shape: BoxShape.circle,
                          ),
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to change photo',
                    style: TextStyle(color: Color(0xFF535353), fontSize: 12),
                  ),

                  const SizedBox(height: 36),

                  // ── Fields ──────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'USERNAME',
                      style: TextStyle(
                        color: Color(0xFFB3B3B3),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'EMAIL',
                      style: TextStyle(
                        color: Color(0xFFB3B3B3),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: _email ?? ''),
                    style: const TextStyle(color: Color(0xFF535353)),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFFCF6679), fontSize: 13)),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Text('Save changes'),
                    ),
                  ),

                  const SizedBox(height: 48),
                  const Divider(color: Color(0xFF282828)),
                  const SizedBox(height: 24),

                  // ── Sign out ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout,
                          color: Color(0xFFCF6679), size: 18),
                      label: const Text(
                        'Sign out',
                        style: TextStyle(
                          color: Color(0xFFCF6679),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    final initial = _usernameController.text.isNotEmpty
        ? _usernameController.text[0].toUpperCase()
        : '?';

    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: NetworkImage(ApiConfig.resolveImageUrl(_avatarUrl!)),
        backgroundColor: const Color(0xFF535353),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: 52,
      backgroundColor: const Color(0xFF535353),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 36,
        ),
      ),
    );
  }
}
