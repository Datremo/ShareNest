import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

class BorrowHubPage extends StatefulWidget {
  const BorrowHubPage({super.key});

  @override
  State<BorrowHubPage> createState() => _BorrowHubPageState();
}

class _BorrowHubPageState extends State<BorrowHubPage> {
  final _listingRepo = ListingRepository();
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'id': null, 'color': AppColors.primaryDark},
    {'name': 'DIY & Tools', 'icon': Icons.handyman_rounded, 'id': 'diy_&_tools', 'color': AppColors.primary},
    {'name': 'Outdoors', 'icon': Icons.park_rounded, 'id': 'camping_&_outdoors', 'color': Colors.green},
    {'name': 'Kitchen', 'icon': Icons.cake_rounded, 'id': 'kitchen_&_party', 'color': Colors.orange},
    {'name': 'Books', 'icon': Icons.menu_book_rounded, 'id': 'books_&_games', 'color': Colors.purple},
    {'name': 'Sports', 'icon': Icons.directions_bike_rounded, 'id': 'sports_&_fitness', 'color': Colors.blue},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded, 'id': 'cleaning_&_home', 'color': Colors.teal},
    {'name': 'Electronics', 'icon': Icons.phone_iphone_rounded, 'id': 'electronics', 'color': Colors.indigo},
    {'name': 'Other', 'icon': Icons.more_horiz_rounded, 'id': 'other', 'color': Colors.grey},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildSearchBar(),
          _buildCategories(),
          _buildItemsGrid(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFF2F4F7),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Borrow Hub',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: GestureDetector(
          onTap: () {
            // Navigate to search results with mode='LEND'
            context.push('/search_results?mode=LEND');
          },
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(CupertinoIcons.search, color: AppColors.primaryDark, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Search to borrow...',
                  style: TextStyle(
                    color: AppColors.primaryDark.withValues(alpha: 0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat['id'] as String?;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? cat['color'] as Color : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (cat['color'] as Color).withValues(alpha: isSelected ? 0.3 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: isSelected ? Colors.white : (cat['color'] as Color),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primaryDark : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildItemsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: StreamBuilder<List<Listing>>(
        stream: _listingRepo.streamListingsByMode('LEND'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              )),
            );
          }
          
          var listings = snapshot.data ?? [];
          if (_selectedCategory != null) {
            listings = listings.where((l) => l.categoryId == _selectedCategory).toList();
          }

          if (listings.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.archivebox, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No items found.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = listings[index];
                return GestureDetector(
                  onTap: () => context.push('/item', extra: item),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: item.photoUrls.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(
                                      item.photoUrls.first,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.image, color: Colors.grey, size: 40),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.locationName ?? 'Nearby',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: listings.length,
            ),
          );
        },
      ),
    );
  }
}
