import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _listingRepo = ListingRepository();
  final _profileRepo = ProfileRepository();
  
  bool _isListView = true;
  String? _selectedCategory;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final profile = await _profileRepo.getProfile(userId);
    if (mounted && profile != null) {
      setState(() => _profile = profile);
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded, 'id': null, 'color': Colors.greenAccent[400]},
    {'name': 'Electronics', 'icon': Icons.laptop_mac, 'id': 'electronics', 'color': Colors.blue[300]},
    {'name': 'Home & Living', 'icon': Icons.chair, 'id': 'cleaning_home', 'color': Colors.green[300]},
    {'name': 'Books', 'icon': Icons.menu_book, 'id': 'books_games', 'color': Colors.orange[300]},
    {'name': 'Sports', 'icon': Icons.sports_basketball, 'id': 'sports_fitness', 'color': Colors.red[300]},
    {'name': 'Tools', 'icon': Icons.handyman, 'id': 'diy_power_tools', 'color': Colors.grey[600]},
    {'name': 'Outdoors', 'icon': Icons.park, 'id': 'camping_outdoors', 'color': Colors.teal[300]},
    {'name': 'Kitchen', 'icon': Icons.cake, 'id': 'kitchen_party', 'color': Colors.pink[300]},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8), // Light gray background matching image
      body: CustomScrollView(
        slivers: [
          _buildTopHeader(),
          _buildTrendingNearby(),
          _buildAllItemsNearby(),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // The background banner image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                child: Image.asset(
                  'assets/images/explore_banner.png', 
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 280,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // Gradient fade for the bottom of the banner
              Positioned(
                bottom: 0, left: 0, right: 0, height: 60,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFFF2F5F8)],
                    ),
                  ),
                ),
              ),
              // SafeArea content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo and Chat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ShareNest', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primaryDark, height: 1.1)),
                                  Text('Borrow • Lend • Exchange • Belong', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                                ],
                              )
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                            ),
                            child: const Icon(CupertinoIcons.chat_bubble_text, color: AppColors.primaryDark, size: 20),
                          )
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Explore title
                      const Text('Explore', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.5, height: 1.0)),
                      const SizedBox(height: 4),
                      const Text('Find what you need, around you.', style: TextStyle(fontSize: 15, color: AppColors.primaryDark, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 24),
                      
                      // Map/List toggle & Location
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _isListView = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: !_isListView ? Colors.greenAccent[400] : Colors.transparent,
                                    ),
                                    child: Row(children: [
                                      Icon(CupertinoIcons.map, size: 16, color: !_isListView ? Colors.white : AppColors.primaryDark), 
                                      const SizedBox(width: 6),
                                      Text('Map View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: !_isListView ? Colors.white : AppColors.primaryDark))
                                    ]),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _isListView = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: _isListView ? Colors.greenAccent[400] : Colors.transparent,
                                    ),
                                    child: Row(children: [
                                      Icon(CupertinoIcons.list_bullet, size: 16, color: _isListView ? Colors.white : AppColors.primaryDark), 
                                      const SizedBox(width: 6),
                                      Text('List View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isListView ? Colors.white : AppColors.primaryDark))
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Location
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text(_profile?.locationName ?? 'Locating...', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // The overlapping Search Bar and Filters - Slide Up significantly!
              Positioned(
                bottom: -24,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/search_results?mode='),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.search, color: AppColors.primaryDark, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Search for items, people...', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500))),
                              Icon(Icons.mic_none, color: Colors.grey[500], size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.tune, color: AppColors.primaryDark, size: 20),
                          SizedBox(width: 8),
                          Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 48), // Spacing for the overlapping search bar
          
          // Categories Row
          _buildCategoriesGrid(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'] || (_selectedCategory == null && cat['id'] == null);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id'] as String?),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? (cat['color'] as Color).withValues(alpha: 0.2) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected ? (cat['color'] as Color) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? (cat['color'] as Color) : AppColors.primaryDark,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingNearby() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Row(
                   children: [
                     const Icon(Icons.trending_up, color: Colors.redAccent), 
                     const SizedBox(width: 8), 
                     const Text('Trending Nearby', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark))
                   ]
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                   child: const Row(
                     children: [
                       Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                       Icon(Icons.chevron_right, size: 14, color: AppColors.primaryDark),
                     ],
                   ),
                 ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180, // Scaled down
            child: StreamBuilder<List<Listing>>(
              stream: _listingRepo.streamActiveListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var listings = snapshot.data ?? [];
                // Filter by category if selected
                if (_selectedCategory != null) {
                  listings = listings.where((l) => l.categoryId == _selectedCategory).toList();
                }
                
                if (listings.isEmpty) {
                  return const Center(child: Text('No trending items right now.', style: TextStyle(color: AppColors.textSecondary)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: listings.length > 5 ? 5 : listings.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final item = listings[index];
                    return GestureDetector(
                      onTap: () => context.push('/item', extra: item),
                      child: Container(
                        width: 140, // Scaled down
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16), 
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top image with badges
                            Expanded(
                              child: Stack(
                                children: [
                                   Container(
                                     width: double.infinity,
                                     decoration: BoxDecoration(
                                       color: Colors.grey[200],
                                       borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                     ),
                                     child: item.photoUrls.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              child: Image.network(item.photoUrls.first, fit: BoxFit.cover),
                                            )
                                          : const Icon(Icons.image, color: Colors.grey),
                                   ),
                                   // Trending badge
                                   Positioned(
                                     top: 8, left: 8, 
                                     child: Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                       decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)), 
                                       child: const Text('Trending', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                     )
                                   ),
                                   // Heart icon
                                   const Positioned(
                                     top: 8, right: 8, 
                                     child: Icon(CupertinoIcons.heart, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 4)])
                                   ),
                                ]
                              )
                            ),
                            // Bottom text
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                                   const SizedBox(height: 4),
                                   Text('${item.locationName ?? 'Nearby'} • 1.2 km', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ]
                              )
                            )
                          ]
                        )
                      ),
                    );
                  },
                );
              }
            )
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAllItemsNearby() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('All Items Nearby', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const Row(
                  children: [
                    Icon(Icons.swap_vert, size: 16, color: AppColors.primaryDark), 
                    SizedBox(width: 4), 
                    Text('Most Relevant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.primaryDark),
                  ]
                ),
              ]
            )
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Listing>>(
            stream: _listingRepo.streamActiveListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ));
              }
              
              var listings = snapshot.data ?? [];
              if (_selectedCategory != null) {
                listings = listings.where((l) => l.categoryId == _selectedCategory).toList();
              }
              
              if (listings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text('No items found.', style: TextStyle(color: AppColors.textSecondary))),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final item = listings[index];
                  
                  // Style pill based on mode
                  Color pillColor;
                  Color pillBgColor;
                  String modeText;
                  if (item.mode == 'LEND') {
                    pillColor = Colors.greenAccent[700]!;
                    pillBgColor = Colors.greenAccent.withValues(alpha: 0.2);
                    modeText = 'Borrow';
                  } else if (item.mode == 'GIVE') {
                    pillColor = Colors.orange;
                    pillBgColor = Colors.orange.withValues(alpha: 0.2);
                    modeText = 'Free';
                  } else {
                    pillColor = Colors.blue;
                    pillBgColor = Colors.blue.withValues(alpha: 0.2);
                    modeText = 'Exchange';
                  }

                  return FutureBuilder<Profile?>(
                    future: _profileRepo.getProfile(item.ownerId),
                    builder: (context, profileSnapshot) {
                      final ownerProfile = profileSnapshot.data;
                      final ownerName = ownerProfile?.displayName.split(' ').first ?? 'Neighbor';
                      final ownerAvatar = ownerProfile?.photoUrl;

                      return GestureDetector(
                        onTap: () => context.push('/item', extra: item),
                        child: Container(
                          height: 110, // Scaled down
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(16), 
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: Row(
                            children: [
                              // Left Image
                              Stack(
                                children: [
                                  Container(
                                    width: 110, 
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16))
                                    ), 
                                    child: item.photoUrls.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                            child: Image.network(item.photoUrls.first, fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.image, color: Colors.grey),
                                  ),
                                  const Positioned(
                                    top: 8, left: 8, 
                                    child: Icon(CupertinoIcons.heart, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 4)])
                                  ),
                                ]
                              ),
                              // Right content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
                                                Text(item.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                              ]
                                            )
                                          ),
                                          // Mode Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: pillBgColor,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(modeText, style: TextStyle(color: pillColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                          )
                                        ]
                                      ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 9, 
                                                  backgroundColor: Colors.grey[300],
                                                  backgroundImage: ownerAvatar != null ? NetworkImage(ownerAvatar) : const AssetImage('assets/images/profile_pic.jpg') as ImageProvider,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(ownerName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                                Expanded(child: Text('${item.locationName ?? 'Nearby'} • 800 m', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                                              ]
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(CupertinoIcons.calendar, size: 12, color: Colors.green[600]),
                                              const SizedBox(width: 4),
                                              Text('Available today', style: TextStyle(fontSize: 10, color: Colors.green[600], fontWeight: FontWeight.w500)),
                                            ]
                                          )
                                        ]
                                      )
                                    ]
                                  )
                                )
                              )
                            ]
                          )
                        ),
                      );
                    }
                  );
                }
              );
            },
          ),
        ],
      )
    );
  }
}
