import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/wishlist_service.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final WishlistService _service = WishlistService();

  bool _loading = true;
  bool _hasPartner = false;
  String? _partnerUsername;
  String? _inviteToken;
  bool _generatingInvite = false;
  bool _accepting = false;
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final status = await _service.getCoupleStatus();
      setState(() {
        _hasPartner = status['hasPartner'] == true;
        _partnerUsername = status['partnerUsername'] as String?;
        final existingToken = status['inviteToken'] as String?;
        if (existingToken != null) _inviteToken = existingToken;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateInvite() async {
    setState(() { _generatingInvite = true; _inviteToken = null; });
    try {
      final token = await _service.generateInviteToken();
      setState(() { _inviteToken = token; _generatingInvite = false; });
    } catch (e) {
      setState(() => _generatingInvite = false);
      if (mounted) {
        final msg = _extractError(e, fallback: 'Could not generate invite code.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFFCF6679)),
        );
      }
    }
  }

  Future<void> _acceptInvite() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Link with partner?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your personal wishlist items will be deleted. You will then share a single wishlist with your partner.\n\nThis cannot be undone.',
          style: TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFCF6679),
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Link accounts'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _accepting = true);
    try {
      await _service.acceptInvite(token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner linked! Your wishlists are now shared.'),
            backgroundColor: Color(0xFF1DB954),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractError(e, fallback: 'Invalid invite code. Try again.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFFCF6679)),
        );
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  String _extractError(Object e, {required String fallback}) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final serverMsg = data['error'] as String?;
        if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)))
          : _hasPartner
              ? _buildLinkedState()
              : _buildUnlinkedState(),
    );
  }

  Widget _buildLinkedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, color: Color(0xFF1DB954), size: 52),
          const SizedBox(height: 20),
          const Text(
            'Sharing with',
            style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            _partnerUsername ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your wishlists are shared.',
            style: TextStyle(color: Color(0xFF535353), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlinkedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          const Text(
            'INVITE YOUR PARTNER',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Generate a code and share it with your partner. They enter it below to link your accounts.',
            style: TextStyle(color: Color(0xFF535353), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),

          if (_inviteToken == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generatingInvite ? null : _generateInvite,
                icon: _generatingInvite
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.link, size: 18),
                label: Text(_generatingInvite ? 'Generating…' : 'Generate invite code'),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1DB954)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _inviteToken!,
                      style: const TextStyle(
                        color: Color(0xFF1DB954),
                        fontSize: 13,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: _inviteToken!));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.copy, color: Color(0xFF1DB954), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expires in 7 days',
                  style: TextStyle(color: Color(0xFF535353), fontSize: 11),
                ),
                TextButton(
                  onPressed: _generateInvite,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Regenerate',
                    style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 40),
          const Divider(color: Color(0xFF282828)),
          const SizedBox(height: 40),

          const Text(
            'GOT A CODE?',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Warning: accepting a code will delete your current wishlist items.',
            style: TextStyle(
              color: Color(0xFFCF6679),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tokenController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Paste invite code here',
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _accepting ? null : _acceptInvite,
              child: _accepting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Accept invite'),
            ),
          ),
        ],
      ),
    );
  }
}
