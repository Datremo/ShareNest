import 'dart:ui';
import 'package:flutter/material.dart';
import 'filters_bottom_sheet.dart';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../../core/maps/sharenest_map.dart';
import '../../../core/location/location_autocomplete_field.dart';
import 'package:geolocator/geolocator.dart' hide Position;
import 'package:geolocator/geolocator.dart' as geo show Position;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  Map<String, dynamic>? _activeFilters;
  final _listingRepo = ListingRepository();
  final _profileRepo = ProfileRepository();
  
  bool _isListView = true;
  String? _selectedCategory;
  Profile? _profile;

  late Future<List<Listing>> _activeListingsFuture;
  RealtimeChannel? _listingsChannel;
  
  geo.Position? _mapCenter;
  String _locationName = 'Navi Mumbai';
  
  Listing? _selectedItem;
  int _nearbyItemsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchListings();
    
    // Listen for real-time changes to refresh the future automatically
    _listingsChannel = Supabase.instance.client.channel('public:listings_explore');
    _listingsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'listings',
      callback: (payload) {
        if (mounted) {
          setState(() {
            _fetchListings();
          });
        }
      },
    ).subscribe();
  }

  void _fetchListings() {
    _activeListingsFuture = _listingRepo.getActiveListings();
  }

  void _onListItemTapped(Listing item) {
    setState(() {
      _selectedItem = item;
      _isListView = false;
      if (item.latitude != null && item.longitude != null) {
         _mapCenter = geo.Position(
           latitude: item.latitude!,
           longitude: item.longitude!,
           timestamp: DateTime.now(),
           accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0
         );
      }
    });
  }

  @override
  void dispose() {
    _listingsChannel?.unsubscribe();
    super.dispose();
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

  Future<void> _showFilters() async {
    final filters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FiltersBottomSheet(),
    );
    if (filters != null) {
      setState(() {
        _activeFilters = filters;
        if (filters['category'] != null && filters['category'] != 'All') {
          _selectedCategory = filters['category'];
        } else {
          _selectedCategory = null;
        }
      });
    }
  }

  Future<void> _openLocationSearch() async {
    final TextEditingController searchController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Search Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
              const SizedBox(height: 24),
              LocationAutocompleteField(
                controller: searchController,
                onSelected: (suggestion) {
                  setState(() {
                    _mapCenter = geo.Position(
                       latitude: suggestion.lat,
                       longitude: suggestion.lon,
                       timestamp: DateTime.now(),
                       accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0
                    );
                    _locationName = suggestion.displayName;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isListView) {
      return Scaffold(
        body: Stack(
          children: [
            FutureBuilder<List<Listing>>(
              future: _activeListingsFuture,
              builder: (context, snapshot) {
                var rawListings = snapshot.data ?? [];
                
                // Apply category filter
                if (_selectedCategory != null) {
                  rawListings = rawListings.where((l) => l.categoryId == _selectedCategory).toList();
                }

                // Apply distance filter (if enabled in activeFilters and we have mapCenter)
                if (_activeFilters != null && _activeFilters!['distance'] != null && _mapCenter != null) {
                  double maxDist = double.tryParse(_activeFilters!['distance'].toString()) ?? 5000;
                  rawListings = rawListings.where((l) {
                    if (l.latitude == null || l.longitude == null) return false;
                    double dist = Geolocator.distanceBetween(
                      _mapCenter!.latitude, _mapCenter!.longitude,
                      l.latitude!, l.longitude!
                    );
                    return dist <= maxDist;
                  }).toList();
                }

                // Apply type filter
                if (_activeFilters != null && _activeFilters!['type'] != null && _activeFilters!['type'] != 'All') {
                  String filterType = _activeFilters!['type'].toString().toUpperCase();
                  rawListings = rawListings.where((l) => l.mode == filterType).toList();
                }

                final mapItems = rawListings.where((p) => p.latitude != null && p.longitude != null).map((p) => {
                  'id': p.id,
                  'title': p.title,
                  'lat': p.latitude,
                  'lng': p.longitude,
                  'type': p.mode == 'LEND' ? 'lend' : (p.mode == 'GIVE' ? 'give' : 'exchange'),
                  'urgency': 'none',
                  'wrapper': p,
                }).toList();

                return ShareNestMap(
                  key: ValueKey('explore_map_${_mapCenter?.latitude ?? 0}'),
                  mode: MapMode.explore,
                  items: mapItems,
                  initialCenter: _mapCenter,
                  selectedItemId: _selectedItem?.id,
                  onItemsInViewChanged: (count) {
                    if (mounted && _nearbyItemsCount != count) {
                      setState(() => _nearbyItemsCount = count);
                    }
                  },
                  onMarkerTapped: (data) {
                    final item = data['wrapper'] as Listing;
                    if (_selectedItem?.id == item.id) {
                      setState(() => _selectedItem = null);
                    } else {
                      setState(() => _selectedItem = item);
                    }
                  },
                  onMapTapped: () {
                    if (_selectedItem != null) {
                      setState(() => _selectedItem = null);
                    }
                  },
                );
              }
            ),
            
            // Floating Top Header & Chips
            SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _openLocationSearch,
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search, color: AppColors.primary, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Search area or address', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                            Text(_locationName, style: const TextStyle(color: AppColors.primaryDark, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showFilters,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: const Row(
                                  children: [
                                    Icon(Icons.tune_rounded, color: AppColors.primaryDark, size: 20),
                                    SizedBox(width: 6),
                                    Text('Filters', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Category Chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat['id']);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? AppColors.primary : Colors.white, width: 1.5),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(cat['icon'] as IconData, size: 14, color: isSelected ? Colors.white : AppColors.primaryDark),
                                    const SizedBox(width: 6),
                                    Text(cat['name'] as String, style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.primaryDark,
                                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                      fontSize: 13
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Nearby Count Indicator
            if (_nearbyItemsCount > 0)
              Positioned(
                top: 130, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Text('$_nearbyItemsCount items nearby', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ),
                    ),
                  ),
                ),
              ),

            // Map Overlay Content / Previews
            if (_selectedItem != null)
              Positioned(
                bottom: 120, // above the map/list switch
                left: 16,
                right: 16,
                child: _buildInlineItemPreview(_selectedItem!),
              ),
              
            // Floating Toggle Switch
            Positioned(
              bottom: 96,
              left: 0,
              right: 0,
              child: Center(child: _buildTogglePill()),
            ),
          ],
        ),
      );
    }

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

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  Widget _buildInlineItemPreview(Listing listing) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          context.push('/items/${listing.id}', extra: listing);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _selectedItem = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: Colors.black54),
                        ),
                      )
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (listing.photoUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            listing.photoUrls.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80, height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryDark, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: listing.mode == 'LEND' ? AppColors.primary.withValues(alpha: 0.1) : AppColors.give.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(listing.mode == 'LEND' ? Icons.handshake_rounded : Icons.card_giftcard_rounded, size: 12, color: listing.mode == 'LEND' ? AppColors.primary : AppColors.give),
                                      const SizedBox(width: 4),
                                      Text(
                                        listing.mode == 'LEND' ? 'Lend' : 'Give',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: listing.mode == 'LEND' ? AppColors.primary : AppColors.give
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.location_on_rounded, size: 12, color: Colors.black54),
                                const SizedBox(width: 2),
                                const Text('~420m away', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Available today', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Text('R', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),
                                const Text('Nearby neighbour', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // directions
                          },
                          icon: const Icon(Icons.navigation_rounded, size: 16, color: Colors.black87),
                          label: const Text('Directions', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade200)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/items/${listing.id}', extra: listing);
                          },
                          icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                          label: const Text('View Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 4,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePill() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
                          _buildTogglePill(),
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
                      child: 
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: TypeAheadField<Listing>(
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search for items...',
                                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                                  prefixIcon: const Icon(CupertinoIcons.search, color: AppColors.primaryDark, size: 20),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.arrow_forward, color: AppColors.primaryDark),
                                    onPressed: () {
                                      context.push('/search_results?mode=&query=${controller.text}');
                                    }
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              );
                            },
                            suggestionsCallback: (pattern) async {
                              if (pattern.isEmpty) return [];
                              return await _listingRepo.searchListings(pattern);
                            },
                            itemBuilder: (context, Listing item) {
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                elevation: 0,
                                color: Colors.grey[50],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: item.photoUrls.isNotEmpty 
                                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.photoUrls.first, width: 50, height: 50, fit: BoxFit.cover)) 
                                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                                  subtitle: Text(item.mode == 'GIVE' ? 'Free' : item.mode == 'LEND' ? 'Borrow' : 'Exchange', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                ),
                              );
                            },
                            onSelected: (Listing item) {
                              context.push('/item', extra: item);
                            },
                            emptyBuilder: (context) => const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No items found', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        )
,
                    ),
                    const SizedBox(width: 12),
                    
                      GestureDetector(
                        onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const FiltersBottomSheet()),
                        child: Container(
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
                      )
,
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
            child: FutureBuilder<List<Listing>>(
              future: _activeListingsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error fetching posts."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var listings = snapshot.data ?? [];
          if (_activeFilters != null) {
            final category = _activeFilters!['category'];
            final condition = _activeFilters!['condition'];
            
            if (category != null && category != 'All') {
                final catId = category.toString().toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');
                listings = listings.where((l) => l.categoryId == catId).toList();
            }
            if (condition != null && condition != 'Any') {
                listings = listings.where((l) => l.condition == condition).toList();
            }
          } else if (_selectedCategory != null) {
            listings = listings.where((l) => l.categoryId == _selectedCategory).toList();
          }

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
                      onTap: () => _onListItemTapped(item),
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
                                     height: double.infinity,
                                     decoration: BoxDecoration(
                                       color: Colors.grey[200],
                                       borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                     ),
                                     child: item.photoUrls.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                              child: Image.network(item.photoUrls.first, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
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
          FutureBuilder<List<Listing>>(
            future: _activeListingsFuture,
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
                        onTap: () => _onListItemTapped(item),
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
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16))
                                    ), 
                                    child: item.photoUrls.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                            child: Image.network(item.photoUrls.first, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
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
