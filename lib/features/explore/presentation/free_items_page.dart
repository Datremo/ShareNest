import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/models/listing.dart';
import 'filters_bottom_sheet.dart';

class FreeItemsPage extends StatefulWidget {
  const FreeItemsPage({super.key});

  @override
  State<FreeItemsPage> createState() => _FreeItemsPageState();
}

class _FreeItemsPageState extends State<FreeItemsPage> {
  final _listingRepo = ListingRepository();
  String _selectedCategory = 'All';
  bool _isListView = true;

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FiltersBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildCategories(),
                  const SizedBox(height: 24),
                  _buildViewToggles(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<List<Listing>>(
                future: _listingRepo.getListingsByMode('GIVE'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    );
                  }
                  final listings = snapshot.data ?? [];
                  if (listings.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.card_giftcard, size: 48, color: AppColors.grey400),
                            SizedBox(height: 12),
                            Text('No free items available yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            SizedBox(height: 4),
                            Text('Be the first to give something away!', style: TextStyle(color: AppColors.give, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${listings.length} free items nearby', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                          const Row(
                            children: [
                              Text('Sort', style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w600)),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primaryDark),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...listings.map((item) => _buildItemCard(
                        listing: item,
                      )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Free Items', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 4),
              Text('Find things people are giving away.\nA little for you. A lot for the planet.', 
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search free items...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryDark),
            onPressed: _showFilters,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': AppColors.primary},
      {'name': 'Food', 'icon': Icons.restaurant_rounded, 'color': Colors.orange},
      {'name': 'Books', 'icon': Icons.menu_book_rounded, 'color': Colors.blue},
      {'name': 'Clothing', 'icon': Icons.checkroom_rounded, 'color': Colors.purple},
      {'name': 'Home', 'icon': Icons.home_rounded, 'color': Colors.green},
      {'name': 'Electronics', 'icon': Icons.phone_iphone_rounded, 'color': Colors.teal},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          bool isSelected = _selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : (cat['color'] as Color), size: 24),
                  const SizedBox(height: 6),
                  Text(cat['name'] as String, style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewToggles() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isListView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isListView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: !_isListView ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: !_isListView ? Colors.white : Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text('Map View', style: TextStyle(color: !_isListView ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isListView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isListView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _isListView ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_list_bulleted_rounded, color: _isListView ? Colors.white : Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text('List View', style: TextStyle(color: _isListView ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({required Listing listing}) {
    return GestureDetector(
      onTap: () => context.push('/item', extra: listing),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              child: listing.photoUrls.isNotEmpty
                  ? Image.network(listing.photoUrls.first, width: 100, height: 110, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 110, color: Colors.grey[200], child: const Icon(Icons.image_outlined, color: AppColors.grey400)),
                    )
                  : Container(width: 100, height: 110, color: Colors.grey[200], child: const Icon(Icons.card_giftcard, color: AppColors.give, size: 32)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const Icon(CupertinoIcons.heart, color: AppColors.primaryDark, size: 18),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(listing.condition ?? 'Good condition', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 12),
                        const SizedBox(width: 3),
                        Expanded(child: Text(listing.locationName ?? 'Nearby', style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 10),
                          SizedBox(width: 3),
                          Text('Free to keep', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
