import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/listing_repository.dart';
import '../../../core/data/repositories/profile_repository.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ListingRepository _listingRepository = ListingRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  Profile? _profile;
  Map<String, int> _globalStats = {
    'neighbours': 0,
    'items': 0,
    'helped': 0,
  };
  Key _refreshKey = UniqueKey();

  late Future<List<Listing>> _activeListingsFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadGlobalStats();
    _fetchListings();
    
    // Auto-refresh stats when tables change
    Supabase.instance.client.channel('public:listings').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'listings',
      callback: (payload) {
        _loadGlobalStats();
        if (mounted) {
          setState(() {
            _fetchListings();
          });
        }
      },
    ).subscribe();
    
    Supabase.instance.client.channel('public:requests').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'requests',
      callback: (payload) => _loadGlobalStats(),
    ).subscribe();
    
    Supabase.instance.client.channel('public:profiles').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      callback: (payload) => _loadGlobalStats(),
    ).subscribe();
  }

  void _fetchListings() {
    _activeListingsFuture = _listingRepository.getActiveListings();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final profile = await _profileRepository.getProfile(userId);
      if (mounted) {
        setState(() => _profile = profile);
      }
    }
  }

  Future<void> _loadGlobalStats() async {
    final stats = await _profileRepository.getGlobalStats();
    if (mounted) {
      setState(() => _globalStats = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA), // Soft pastel background
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          _loadProfile();
          _loadGlobalStats();
    _fetchListings();
          setState(() {
            _refreshKey = UniqueKey();
          });
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 14),
              _buildBottomStatsBanner(),
              const SizedBox(height: 22),
              FutureBuilder<List<Listing>>(
                key: _refreshKey,
                future: _activeListingsFuture,
                builder: (context, snapshot) {
                  final allItems = snapshot.data ?? [];
                  final lendItems = allItems.where((l) => l.mode == 'LEND').toList();
                  final giveItems = allItems.where((l) => l.mode == 'GIVE').toList();
                  final exchangeItems = allItems.where((l) => l.mode == 'EXCHANGE').toList();
                  
                  return Column(
                    children: [
                      if (lendItems.isNotEmpty) ...[
                        _buildCarouselSection(
                          title: 'Trending in Borrowing',
                          icon: Icons.inventory_2_rounded,
                          iconColor: const Color(0xFF34C759),
                          route: '/borrow_hub',
                          items: lendItems,
                        ),
                        const SizedBox(height: 22),
                      ],
                      if (giveItems.isNotEmpty) ...[
                        _buildCarouselSection(
                          title: 'Trending Free Items',
                          icon: Icons.card_giftcard_rounded,
                          iconColor: const Color(0xFFFF9500),
                          route: '/free_items',
                          items: giveItems,
                        ),
                        const SizedBox(height: 22),
                      ],
                    ],
                  );
                }
              ),
              const SizedBox(height: 22),
              _buildMidBanner(),
              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    final name = _profile?.displayName.split(' ').first ?? 'Neighbor';
    final location = _profile?.locationName ?? 'Panvel, Navi Mumbai';

    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning,';
    } else if (hour < 17) {
      greeting = 'Good afternoon,';
    } else if (hour < 21) {
      greeting = 'Good evening,';
    } else {
      greeting = 'Good night,';
    }

    return Stack(
      children: [
        // Background Image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 440,
          child: ShaderMask(
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.6, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/neighborhood_banner.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Floating decorative texts
        Positioned(
          top: 90,
          right: 18,
          child: Transform.rotate(
            angle: 0.1,
            child: Text(
              'Good\nPeople\nBrighter\nNeighbourhoods',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C3E50).withValues(alpha: 0.8),
                height: 1.0,
              ),
            ),
          ),
        ),
        Positioned(
          top: 135,
          right: 32,
          child: Transform.rotate(
            angle: 0.1,
            child: const Icon(CupertinoIcons.heart, size: 14, color: Color(0xFF2C3E50)),
          ),
        ),
        
        Positioned(
          top: 180,
          right: -10,
          child: Transform.rotate(
            angle: -0.1,
            child: Text(
              'Share\nMore\nLive\nBetter',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C3E50).withValues(alpha: 0.8),
                height: 1.0,
              ),
            ),
          ),
        ),
        Positioned(
          top: 250,
          right: 18,
          child: Transform.rotate(
            angle: -0.1,
            child: const Icon(CupertinoIcons.heart, size: 14, color: Color(0xFF2C3E50)),
          ),
        ),

        // Foreground Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Custom App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png', 
                          height: 38, 
                          errorBuilder: (_,__,___) => const Icon(Icons.energy_savings_leaf, color: AppColors.primary, size: 36)
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ShareNest',
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: -0.5, height: 1.1),
                            ),
                            Text(
                              'Borrow • Lend • Exchange • Belong',
                              style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF64748B), fontWeight: FontWeight.w600, height: 1.1),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(CupertinoIcons.chat_bubble_text_fill, color: Color(0xFF1E293B), size: 20),
                        onPressed: () => context.push('/messages'),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                
                // Greeting
                Text(
                  greeting,
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B), letterSpacing: -0.5),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.0, letterSpacing: -1.5),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4.0),
                      child: Text('👋', style: TextStyle(fontSize: 28)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Same neighbourhood.\nMore possibilities.',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B), height: 1.2),
                ),
                const SizedBox(height: 14),
                
                // Location Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        location,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 14),
                    ],
                  ),
                ),
                
                const SizedBox(height: 36),
                
                // Action Row (Fitted perfectly)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionPill(
                        title: 'Borrow',
                        subtitle: 'Find items',
                        icon: Icons.inventory_2_rounded,
                        topColor: const Color(0xFFE5F9E9),
                        bottomColor: const Color(0xFF9EE8B5),
                        btnColor: const Color(0xFF34C759),
                        onTap: () => context.push('/borrow_hub'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionPill(
                        title: 'Get Free',
                        subtitle: 'Take what you need',
                        icon: Icons.card_giftcard_rounded,
                        topColor: const Color(0xFFFFF2E5),
                        bottomColor: const Color(0xFFFFC085),
                        btnColor: const Color(0xFFFF9500),
                        onTap: () => context.push('/free_items'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionPill(
                        title: 'Need It Now',
                        subtitle: 'Urgent help',
                        icon: Icons.bolt_rounded,
                        topColor: const Color(0xFFFFE5E5),
                        bottomColor: const Color(0xFFFF9E9E),
                        btnColor: const Color(0xFFE53935),
                        onTap: () => context.push('/live_radar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color topColor,
    required Color bottomColor,
    required Color btnColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140, // Reduced height for the perfectly fitting cards
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor.withValues(alpha: 0.8), bottomColor.withValues(alpha: 0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: bottomColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: btnColor, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB91C1C),
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: btnColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMidBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFEAF5EF), Color(0xFFF1F8F4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: 0,
              child: Image.asset('assets/images/people_illustration.png', height: 90, errorBuilder: (_,__,___) => const SizedBox()),
            ),
            Positioned(
              right: 10,
              top: 12,
              child: Transform.rotate(
                angle: 0.1,
                child: Text(
                  'Neighbours\nhelp\nneighbours',
                  style: GoogleFonts.caveat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF2C3E50)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              right: 22,
              top: 54,
              child: Transform.rotate(
                angle: 0.1,
                child: const Icon(CupertinoIcons.heart, size: 10, color: Color(0xFF2C3E50)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.energy_savings_leaf, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A stronger neighbourhood starts\nwith small actions.',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), height: 1.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real people. Real help. Real impact.',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Join the Community', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomStatsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFFEAF5EF), Color(0xFFEAF0FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            // Left text section
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.energy_savings_leaf, color: AppColors.primary, size: 32),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Small Actions\nBig Change',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), height: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Together for a greener tomorrow.',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right stats section
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(Icons.people, const Color(0xFF34C759), _formatStat(_globalStats['neighbours'] ?? 0), 'Neighbours'),
                  _buildStatItem(Icons.energy_savings_leaf, const Color(0xFFAF52DE), _formatStat(_globalStats['items'] ?? 0), 'Items Shared'),
                  _buildStatItem(CupertinoIcons.heart_fill, const Color(0xFFFF3B30), _formatStat(_globalStats['helped'] ?? 0), 'Helped Together'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStat(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildCarouselSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String route,
    required List<Listing> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18, 
                          fontWeight: FontWeight.w800, 
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push(route),
                    child: Row(
                      children: [
                        Text('See All', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12)),
                        const Icon(Icons.chevron_right, size: 14, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length > 5 ? 5 : items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildItemCard(items[index]),
                  );
                },
              ),
            ),
          ],
        );
  }

  Widget _buildItemCard(Listing item) {
    return GestureDetector(
      onTap: () => context.push('/item', extra: item),
      child: Container(
        width: 145,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 108,
                      width: double.infinity,
                      child: item.photoUrls.isNotEmpty
                          ? Image.network(item.photoUrls.first, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.image_rounded, color: Color(0xFFCBD5E1), size: 36),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.availability != null && item.availability!.isNotEmpty 
                            ? 'Avail: ' + (item.availability!.first.length > 10 ? item.availability!.first.substring(5, 10) : item.availability!.first)
                            : '1.2 km',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(CupertinoIcons.heart, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            // Text Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description ?? '',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
