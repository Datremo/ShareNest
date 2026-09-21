import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/data/repositories/profile_repository.dart';
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

  List<String> get _images => _currentListing.photoUrls;

  @override
  void initState() {
    super.initState();
    _currentListing = widget.listing;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndCategory(),
                    const SizedBox(height: 12),
                    _buildItemTags(),
                    const SizedBox(height: 16),
                    _buildDescription(),
                    const Divider(height: 32, color: AppColors.grey200, thickness: 1),
                    _buildOwnerProfile(),
                    const Divider(height: 32, color: AppColors.grey200, thickness: 1),
                    _buildTagsAndInclusions(),
                    _buildLocation(),
                    if (_currentListing.availability != null && _currentListing.availability!.isNotEmpty) ...[
                      const Divider(height: 32, color: AppColors.grey200, thickness: 1),
                      _buildAvailability(),
                    ],
                    const Divider(height: 32, color: AppColors.grey200, thickness: 1),
                    _buildSafetyGuidelines(),
                    const SizedBox(height: 120),
                  ],
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
      expandedHeight: 300,
      pinned: true,
      
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) {
                setState(() => _currentImageIndex = idx);
              },
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
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey)),
                    ),
                  ),
                );
              },
            ),
            if (_images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
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

  void _showFullScreenImage(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    child: Image.network(
                      _images[index],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleAndCategory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _currentListing.categoryId.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: 1.2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentListing.mode.toUpperCase() == 'LEND' ? AppColors.primaryDark : (_currentListing.mode.toUpperCase() == 'GIVE' ? AppColors.success : AppColors.exchange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentListing.mode.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentListing.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildItemTags() {
    final prefs = _currentListing.preferences;
    final returnPeriod = prefs != null ? prefs['returnPeriod'] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailCard(Icons.info_outline, 'Condition', _currentListing.condition ?? 'Good', AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildDetailCard(Icons.branding_watermark_outlined, 'Brand', (_currentListing.brand?.isNotEmpty == true) ? _currentListing.brand! : 'Unbranded', Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailCard(Icons.inventory_2_outlined, 'Quantity', '${_currentListing.quantity ?? 1} Available', Colors.teal)),
              const SizedBox(width: 12),
              if (_currentListing.mode.toUpperCase() == 'LEND' && returnPeriod != null)
                Expanded(child: _buildDetailCard(Icons.assignment_return_outlined, 'Return Period', returnPeriod.toString(), Colors.purple))
              else
                Expanded(child: const SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About this item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            (_currentListing.description?.isNotEmpty == true) ? _currentListing.description! : 'No description provided.',
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerProfile() {
    return FutureBuilder<Profile?>(
      future: ProfileRepository().getProfile(_currentListing.ownerId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final displayName = profile?.displayName ?? '${_currentListing.ownerId.substring(0, 5)}...';
        final photoUrl = profile?.photoUrl;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                  child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person, color: AppColors.primary, size: 28) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Listed by', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      if (isLoading)
                        Container(width: 100, height: 16, color: Colors.grey[200])
                      else
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.verified, color: AppColors.primary, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified Neighbor',
                            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pickup Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentListing.locationName ?? 'Location not specified',
                    style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    String formattedAvailability = '';
    if (_currentListing.availability != null && _currentListing.availability!.length >= 2) {
      try {
        final start = DateTime.parse(_currentListing.availability![0]);
        final end = DateTime.parse(_currentListing.availability![1]);
        formattedAvailability = '${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
      } catch (e) {
        formattedAvailability = _currentListing.availability!.join(' - ');
      }
    }

    if (formattedAvailability.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(formattedAvailability, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsAndInclusions() {
    final prefs = _currentListing.preferences;
    if (prefs == null) return const SizedBox.shrink();

    final List<dynamic>? tags = prefs['tags'];
    final List<dynamic>? includedItems = prefs['includedItems'];

    if ((tags == null || tags.isEmpty) && (includedItems == null || includedItems.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags != null && tags.isNotEmpty) ...[
            const Text('Tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((t) => Chip(
                label: Text(t.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                backgroundColor: AppColors.grey100,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (includedItems != null && includedItems.isNotEmpty) ...[
            const Text('What\'s in the box', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              children: includedItems.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    const SizedBox(width: 12),
                    Text(i.toString(), style: const TextStyle(fontSize: 15)),
                  ],
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyGuidelines() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.shield, color: Colors.orange),
                SizedBox(width: 8),
                Text('Safety & Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            _bulletPoint('Treat the item with care.'),
            _bulletPoint('Return on time.'),
            _bulletPoint('Report any issues in the app.'),
            _bulletPoint('Meet in a safe, public location.'),
          ],
        ),
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context) {
    final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final bool isOwner = currentUserId == _currentListing.ownerId;

    if (isOwner) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () async {
                      final updated = await context.push<Listing?>('/edit_post', extra: _currentListing);
                      if (updated != null && mounted) {
                        setState(() => _currentListing = updated);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryDark, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: const Text(
                      'Edit Post',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/owner_requests_list', extra: _currentListing);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: const Text(
                      'Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    String ctaText = 'Request Item';
    String route = '/request-borrow'; // fallback
    Color btnColor = AppColors.primaryDark;

    switch (_currentListing.mode.toUpperCase()) {
      case 'LEND':
        ctaText = 'Request to Borrow';
        route = '/request_borrow';
        break;
      case 'GIVE':
        ctaText = 'Request Free Item';
        route = '/request_free_item';
        btnColor = AppColors.success;
        break;
      case 'EXCHANGE':
        ctaText = 'Request Exchange';
        route = '/request_exchange';
        btnColor = AppColors.exchange;
        break;
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.push(route, extra: _currentListing);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: btnColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text(
                    ctaText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
