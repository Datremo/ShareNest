import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/repositories/request_repository.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/presentation/widgets/glassmorphism.dart';
import '../../requests/presentation/owner_request_detail_page.dart';

class ItemDetailPage extends StatefulWidget {
  final Listing listing;
  const ItemDetailPage({super.key, required this.listing});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late Listing _currentListing;
  Profile? _ownerProfile;
  bool _isLoadingOwner = true;
  int _pendingRequestsCount = 0;
  bool _isLoadingRequests = true;

  List<String> get _images => _currentListing.photoUrls;
  bool get _isOwner => Supabase.instance.client.auth.currentUser?.id == _currentListing.ownerId;

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
    _fetchOwner();
    if (_isOwner) {
      _fetchRequests();
    } else {
      _isLoadingRequests = false;
    }
  }

  Future<void> _fetchOwner() async {
    try {
      final profile = await ProfileRepository().getProfile(_currentListing.ownerId);
      if (mounted) setState(() => _ownerProfile = profile);
    } catch (e) {
      debugPrint('Failed to load owner profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingOwner = false);
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final requests = await RequestRepository().getRequestsForListing(_currentListing.id);
      if (mounted) {
        setState(() {
          _pendingRequestsCount = requests.where((r) => r['status'] == 'PENDING').length;
        });
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showFullScreenImage(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: index),
              itemCount: _images.length,
              itemBuilder: (context, i) => InteractiveViewer(
                child: Image.network(_images[i], fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Stack(
        children: [
          // Background Orbs
          Positioned(top: -100, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.15)))),
          Positioned(bottom: 50, left: -100, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withValues(alpha: 0.1)))),
          
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildHeader(),
                      const SizedBox(height: 16),
                      if (_currentListing.description != null && _currentListing.description!.isNotEmpty) ...[
                        _buildDescription(),
                        const SizedBox(height: 16),
                      ],
                      _buildInfoGrid(),
                      const SizedBox(height: 24),
                      _buildTagsAndItems(),
                      const SizedBox(height: 24),
                      _buildOwnerProfile(),
                      const SizedBox(height: 24),
                      _buildSafetyGuidelines(),
                      const SizedBox(height: 140), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildStickyBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
              itemCount: _images.isEmpty ? 1 : _images.length,
              itemBuilder: (context, index) {
                if (_images.isEmpty) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey)),
                  );
                }
                return GestureDetector(
                  onTap: () => _showFullScreenImage(index),
                  child: Image.network(
                    _images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay at bottom of image for seamless transition
            Positioned(
              bottom: 0, left: 0, right: 0, height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, const Color(0xFFF2F4F7).withValues(alpha: 0.8), const Color(0xFFF2F4F7)],
                  ),
                ),
              ),
            ),
            if (_images.length > 1)
              Positioned(
                bottom: 24, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text(
                _currentListing.mode.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                _currentListing.categoryId.replaceAll('_', ' ').toUpperCase(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _currentListing.title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryDark, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Text(
            _currentListing.description ?? '',
            style: TextStyle(fontSize: 15, height: 1.6, color: AppColors.primaryDark.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    String formattedAvailability = 'Not specified';
    if (_currentListing.availability != null && _currentListing.availability!.length >= 2) {
      try {
        final start = DateTime.parse(_currentListing.availability![0]);
        final end = DateTime.parse(_currentListing.availability![1]);
        formattedAvailability = '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
      } catch (e) {
        formattedAvailability = _currentListing.availability!.join(' - ');
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _buildInfoTile('Condition', _currentListing.condition ?? 'Not specified', Icons.verified_rounded),
        if (_currentListing.locationName != null && _currentListing.locationName!.isNotEmpty)
          _buildInfoTile('Location', _currentListing.locationName!, Icons.location_on_rounded),
        if (_currentListing.mode == 'LEND' || _currentListing.mode == 'GIVE')
          _buildInfoTile('Availability', formattedAvailability, Icons.calendar_month_rounded),
        if (_currentListing.preferences != null && _currentListing.preferences!['returnPeriod'] != null)
          _buildInfoTile('Return Period', _currentListing.preferences!['returnPeriod'], Icons.timer_rounded),
        if (_currentListing.quantity != null && _currentListing.quantity! > 0)
          _buildInfoTile('Quantity', _currentListing.quantity.toString(), Icons.numbers_rounded),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    // Generate a unique subtle colorful gradient based on the title
    final colors = {
      'Condition': [const Color(0xFFE8F5E9).withValues(alpha: 0.7), const Color(0xFFC8E6C9).withValues(alpha: 0.5)], // Green tint
      'Location': [const Color(0xFFE3F2FD).withValues(alpha: 0.7), const Color(0xFFBBDEFB).withValues(alpha: 0.5)], // Blue tint
      'Availability': [const Color(0xFFFFF3E0).withValues(alpha: 0.7), const Color(0xFFFFE0B2).withValues(alpha: 0.5)], // Orange tint
      'Return Period': [const Color(0xFFF3E5F5).withValues(alpha: 0.7), const Color(0xFFE1BEE7).withValues(alpha: 0.5)], // Purple tint
    };
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors[title] ?? [Colors.white.withValues(alpha: 0.6), Colors.white.withValues(alpha: 0.4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey[600], letterSpacing: 0.5), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTagsAndItems() {
    final prefs = _currentListing.preferences ?? {};
    final tags = (prefs['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final items = (prefs['includedItems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    if (tags.isEmpty && items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty) ...[
          const Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text('#$tag', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            )).toList(),
          ),
          if (items.isNotEmpty) const SizedBox(height: 24),
        ],
        if (items.isNotEmpty) ...[
          const Text('In The Box', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryDark, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.primaryDark))),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOwnerProfile() {
    if (_ownerProfile == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        context.push('/user_profile?userId=${_ownerProfile!.id}');
      },
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.4),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, Colors.blueAccent]),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: _ownerProfile!.photoUrl != null ? NetworkImage(_ownerProfile!.photoUrl!) : null,
                backgroundColor: Colors.white,
                child: _ownerProfile!.photoUrl == null
                    ? Text(_ownerProfile!.displayName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 24))
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Owned by', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(_ownerProfile!.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text('${_ownerProfile!.trustScore} Trust Score', style: const TextStyle(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyGuidelines() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.orange.shade50.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Safety & Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          _bulletPoint('Treat the item with care and respect.'),
          _bulletPoint('Return exactly on the agreed date.'),
          _bulletPoint('Meet in safe, public locations.'),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.primaryDark, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                if (_isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.primaryDark),
                    onPressed: () async {
                      final updated = await context.push('/edit_post', extra: _currentListing);
                      if (updated != null && updated is Listing) {
                        setState(() {
                          _currentListing = updated;
                        });
                      }
                    },
                    tooltip: 'Edit Post',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'Delete Post',
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: _isOwner
                      ? GlassButton(
                          label: 'View All Requests',
                          icon: Icons.inbox_rounded,
                          onPressed: () {
                            context.push('/owner_requests_list', extra: _currentListing);
                          },
                        )
                      : GlassButton(
                          label: _currentListing.mode == 'LEND'
                              ? 'Request to Borrow'
                              : _currentListing.mode == 'GIVE'
                                  ? 'Request Item'
                                  : 'Offer Exchange',
                          icon: Icons.handshake_rounded,
                          onPressed: () {
                            if (_currentListing.mode == 'LEND') {
                              context.push('/request_borrow', extra: _currentListing);
                            } else if (_currentListing.mode == 'GIVE') {
                              context.push('/request_free_item', extra: _currentListing);
                            } else {
                              context.push('/request_exchange', extra: _currentListing);
                            }
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      await ListingRepository().deleteListing(_currentListing.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
