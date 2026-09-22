import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _listingRepo = ListingRepository();
  bool _isListView = true;
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view},
    {'name': 'Tools', 'icon': Icons.handyman},
    {'name': 'Electronics', 'icon': Icons.computer},
    {'name': 'Home', 'icon': Icons.home},
    {'name': 'Books', 'icon': Icons.menu_book},
    {'name': 'More', 'icon': Icons.more_horiz},
  ];

  void _openFilters() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const _FiltersFullScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: AppColors.textPrimary, size: 20),
                      const SizedBox(width: 4),
                      const Text('Sainagar, Old Panvel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.turn_right, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
                  SizedBox(height: 4),
                  Text('Discover useful items and kind neighbours near you.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Search & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for tools, books, appliances...',
                          hintStyle: TextStyle(color: AppColors.grey400, fontSize: 14),
                          prefixIcon: Icon(CupertinoIcons.search, color: AppColors.textPrimary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _openFilters,
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: const SizedBox(
                        height: 52,
                        width: 52,
                        child: Icon(Icons.tune, color: AppColors.textPrimary),
                      ),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Categories
            SizedBox(
              height: 70,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = index == _selectedCategoryIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: Container(
                      width: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              shape: BoxShape.circle,
                              border: isSelected ? null : Border.all(color: AppColors.grey200),
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: isSelected ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Segmented Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.grey100, // Very light grey background
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    // Animated background for selection
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: _isListView ? Alignment.centerRight : Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isListView = false),
                            child: Container(
                              color: Colors.transparent,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_outlined, size: 18, color: !_isListView ? Colors.white : AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Map View',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !_isListView ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isListView = true),
                            child: Container(
                              color: Colors.transparent,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.format_list_bulleted, size: 18, color: _isListView ? Colors.white : AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'List View',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isListView ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            Expanded(
              child: _isListView ? _buildListView() : _buildMapView(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return FutureBuilder<List<Listing>>(
      future: _listingRepo.getActiveListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.grey400),
                SizedBox(height: 12),
                Text('No items near you yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                SizedBox(height: 4),
                Text('Be the first to share!', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${listings.length} items near you', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Row(
                    children: [
                      Icon(Icons.sort, size: 14, color: AppColors.textPrimary),
                      SizedBox(width: 4),
                      Text('Sort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                itemCount: listings.length,
                separatorBuilder: (context, index) => const Divider(height: 24, color: AppColors.grey200),
                itemBuilder: (context, index) {
                  final item = listings[index];
                  Color tagColor = AppColors.borrow;
                  String tagLabel = 'Lend';
                  if (item.mode == 'GIVE') { tagColor = AppColors.give; tagLabel = 'Free'; }
                  if (item.mode == 'EXCHANGE') { tagColor = AppColors.exchange; tagLabel = 'Exchange'; }
                  return _buildListingRow(item, tagColor, tagLabel);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListingRow(Listing item, Color tagColor, String tagLabel) {
    return PhysicsCard(
      onTap: () => context.push('/item', extra: item),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
                image: item.photoUrls.isNotEmpty
                    ? DecorationImage(image: NetworkImage(item.photoUrls.first), fit: BoxFit.cover)
                    : null,
              ),
              child: item.photoUrls.isEmpty
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: const Icon(Icons.image_outlined, color: AppColors.primaryDark, size: 28),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.favorite_border, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.locationName ?? 'Nearby',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tagColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: tagColor, size: 10),
                        const SizedBox(width: 3),
                        Text(tagLabel, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      color: const Color(0xFFE8E5DD),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: AppColors.grey400),
            SizedBox(height: 12),
            Text('Map View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            SizedBox(height: 4),
            Text('Coming soon', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Full Screen Filters Modal
// ---------------------------------------------------------
class _FiltersFullScreen extends StatefulWidget {
  const _FiltersFullScreen();

  @override
  State<_FiltersFullScreen> createState() => _FiltersFullScreenState();
}

class _FiltersFullScreenState extends State<_FiltersFullScreen> {
  bool _verifiedOnly = false;
  bool _highlyRated = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Filters', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Clear All', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What are you looking for?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLookingFor('All', Icons.grid_view, true, AppColors.primary),
                _buildLookingFor('Borrow', Icons.handyman, false, AppColors.borrow),
                _buildLookingFor('Give', Icons.card_giftcard, false, AppColors.give),
                _buildLookingFor('Exchange', Icons.swap_horiz, false, AppColors.exchange),
                _buildLookingFor('Need', Icons.bolt, false, AppColors.urgent),
              ],
            ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Row(
                  children: [
                    Text('See all', style: TextStyle(color: AppColors.textPrimary)),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildCategoryChip('Tools & Hardware', Icons.handyman),
                _buildCategoryChip('Electronics', Icons.computer),
                _buildCategoryChip('Home & Kitchen', Icons.home),
                _buildCategoryChip('Books & Learning', Icons.menu_book),
                _buildCategoryChip('Sports & Outdoors', Icons.pedal_bike),
                _buildCategoryChip('Clothing & Accessories', Icons.checkroom),
                _buildCategoryChip('Toys & Games', Icons.toys),
                _buildCategoryChip('Garden & Plants', Icons.local_florist),
              ],
            ),
            
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Within 5 km', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.grey200,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: 5,
                min: 0,
                max: 10,
                divisions: 4,
                onChanged: (val) {},
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('500 m', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('1 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('2 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('5 km', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('10+ km', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Condition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                _buildConditionPill('Any', true),
                _buildConditionPill('Like New', false),
                _buildConditionPill('Good', false),
                _buildConditionPill('Fair', false),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Available now', style: TextStyle(fontSize: 16))),
                CupertinoSwitch(value: true, activeColor: AppColors.primary, onChanged: (v) {})
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Flexible timing', style: TextStyle(fontSize: 16))),
                CupertinoSwitch(value: false, activeColor: AppColors.primary, onChanged: (v) {})
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('Trust & Safety', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Verified users only', style: TextStyle(fontSize: 16))),
                CupertinoSwitch(value: _verifiedOnly, activeColor: AppColors.primary, onChanged: (v) => setState(() => _verifiedOnly = v))
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Highly rated (4.0+)', style: TextStyle(fontSize: 16))),
                CupertinoSwitch(value: _highlyRated, activeColor: AppColors.primary, onChanged: (v) => setState(() => _highlyRated = v))
              ],
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Apply Filters (124 items)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLookingFor(String label, IconData icon, bool isSelected, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isSelected ? null : Border.all(color: AppColors.grey200),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildConditionPill(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey200),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
