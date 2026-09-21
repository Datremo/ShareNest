import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/models/listing.dart';

class BorrowHubPage extends StatefulWidget {
  const BorrowHubPage({super.key});

  @override
  State<BorrowHubPage> createState() => _BorrowHubPageState();
}

class _BorrowHubPageState extends State<BorrowHubPage> {
  final _listingRepo = ListingRepository();

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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchBar(context),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRecentListings(),
                  const SizedBox(height: 32),
                  const Text('Popular searches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildPopularChip(context, 'Drill', true),
                      _buildPopularChip(context, 'Ladder', false),
                      _buildPopularChip(context, 'Tent', false),
                      _buildPopularChip(context, 'Projector', false),
                      _buildPopularChip(context, 'Camera', false),
                      _buildPopularChip(context, 'Cycle', false),
                      _buildPopularChip(context, 'Books', false),
                      _buildPopularChip(context, 'Kitchen items', false),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Or browse categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      Text('See all', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildCategoriesGrid(),
                ],
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Borrow Something', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 4),
              Text('Find useful items nearby.\nUse it. Return it. Simple.', 
                style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/borrow_results'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Icon(CupertinoIcons.search, color: AppColors.primaryDark, size: 20),
            ),
            const Expanded(
              child: Text('drill', style: TextStyle(fontSize: 16, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
            ),
            IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () {}),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.primaryDark),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularChip(BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => context.push('/borrow_results'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryDark, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'Tools', 'icon': Icons.build_rounded, 'color': AppColors.primary},
      {'name': 'Electronics', 'icon': Icons.phone_iphone_rounded, 'color': Colors.teal},
      {'name': 'Home &\nKitchen', 'icon': Icons.home_rounded, 'color': Colors.orange},
      {'name': 'Sports', 'icon': Icons.directions_bike_rounded, 'color': Colors.blue},
      {'name': 'Books', 'icon': Icons.menu_book_rounded, 'color': Colors.purple},
      {'name': 'Clothing', 'icon': Icons.checkroom_rounded, 'color': Colors.pink},
      {'name': 'Outdoor', 'icon': Icons.park_rounded, 'color': Colors.green},
      {'name': 'More', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        bool isSelected = cat['name'] == 'Tools';
        return Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
              ),
              child: Icon(cat['icon'] as IconData, color: isSelected ? AppColors.primary : (cat['color'] as Color), size: 24),
            ),
            const SizedBox(height: 8),
            Text(cat['name'] as String, textAlign: TextAlign.center, style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.primaryDark,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              height: 1.2
            )),
          ],
        );
      },
    );
  }

  Widget _buildRecentListings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available to borrow right now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<Listing>>(
            future: _listingRepo.getListingsByMode('LEND'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return const Center(child: Text('No items available to borrow right now.', style: TextStyle(color: AppColors.textSecondary)));
              }
              
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: listings.length > 5 ? 5 : listings.length, // Show up to 5
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final item = listings[index];
                  return GestureDetector(
                    onTap: () => context.push('/item', extra: item),
                    child: Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: item.photoUrls.isNotEmpty
                                ? Image.network(item.photoUrls.first, height: 120, width: double.infinity, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey[100], child: const Icon(Icons.image_outlined, color: AppColors.grey400)))
                                : Container(height: 120, color: Colors.grey[100], child: const Icon(Icons.handyman, color: AppColors.borrow, size: 32)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(item.locationName ?? 'Nearby', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
