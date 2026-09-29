import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/urgent_request.dart';
import '../../../core/data/repositories/listing_repository.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedFilter = 'All';

  List<Listing> _myListings = [];
  List<UrgentRequest> _myUrgentRequests = [];
  Map<String, int> _listingRequestCounts = {};
  Map<String, int> _urgentOfferCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRealData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRealData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final listingsRes = await Supabase.instance.client
          .from('listings')
          .select('*, item_requests!item_requests_listing_id_fkey(id)')
          .eq('owner_id', user.id)
          .neq('status', 'HIDDEN')
          .order('created_at', ascending: false);

      final urgentRes = await Supabase.instance.client
          .from('urgent_requests')
          .select('*, urgent_request_offers(id)')
          .eq('requester_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myListings = [];
          _listingRequestCounts = {};
          for (var l in listingsRes) {
            _myListings.add(Listing.fromJson(l));
            _listingRequestCounts[l['id']] = (l['item_requests'] as List?)?.length ?? 0;
          }

          _myUrgentRequests = [];
          _urgentOfferCounts = {};
          for (var u in urgentRes) {
            _myUrgentRequests.add(UrgentRequest.fromJson(u));
            _urgentOfferCounts[u['id']] = (u['urgent_request_offers'] as List?)?.length ?? 0;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching my posts: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Listing> get _filteredListings {
    if (_selectedFilter == 'All') return _myListings;
    return _myListings.where((l) => l.mode.toUpperCase() == _selectedFilter.toUpperCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.5),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            const Text('My Offerings', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
            Text('Manage your listings & requests', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primary,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Listings'),
                Tab(text: 'Need It Now'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                Positioned(
                  top: 100, right: -50,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      boxShadow: [BoxShadow(blurRadius: 100, color: AppColors.primary.withValues(alpha: 0.2))],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100, left: -50,
                  child: Container(
                    width: 300, height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withValues(alpha: 0.05),
                      boxShadow: [BoxShadow(blurRadius: 100, color: Colors.blue.withValues(alpha: 0.1))],
                    ),
                  ),
                ),
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListingsTab(),
                    _buildUrgentTab(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildListingsTab() {
    return Column(
      children: [
        const SizedBox(height: 140),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['All', 'Lend', 'Give'].map((f) {
              final isSelected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                    ),
                    child: Text(
                      f,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _filteredListings.isEmpty
              ? _buildEmptyState('No listings found', Icons.inventory_2_outlined)
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredListings.length,
                    itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 400),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildListingCard(_filteredListings[index]),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUrgentTab() {
    return _myUrgentRequests.isEmpty
        ? _buildEmptyState('No urgent requests found', Icons.bolt_rounded)
        : AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 140, bottom: 100),
              physics: const BouncingScrollPhysics(),
              itemCount: _myUrgentRequests.length,
              itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildUrgentCard(_myUrgentRequests[index]),
                  ),
                ),
              ),
            ),
          );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.6),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    Color badgeColor = listing.mode.toUpperCase() == 'LEND' ? AppColors.primary : AppColors.give;
    final hasImage = listing.photoUrls.isNotEmpty;
    final reqCount = _listingRequestCounts[listing.id] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/item', extra: listing).then((_) => _fetchRealData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: hasImage
                          ? Image.network(listing.photoUrls.first, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor.withValues(alpha: 0.2))),
                              child: Text(listing.mode.toUpperCase(), style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: listing.status == 'ACTIVE' ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: listing.status == 'ACTIVE' ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey.shade300)
                              ),
                              child: Text(listing.status, style: TextStyle(
                                color: listing.status == 'ACTIVE' ? AppColors.primary : Colors.grey.shade600,
                                fontSize: 10, fontWeight: FontWeight.w900
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(listing.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('$reqCount requests', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(DateFormat('MMM d').format(listing.createdAt ?? DateTime.now()), style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentCard(UrgentRequest request) {
    final offerCount = _urgentOfferCounts[request.id] ?? 0;
    return GestureDetector(
      onTap: () => context.push('/urgent_request/${request.id}').then((_) => _fetchRealData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFEF4444)),
                            const SizedBox(width: 4),
                            const Text('NEED IT NOW', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: request.status == 'ACTIVE' ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: request.status == 'ACTIVE' ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey.shade300),
                        ),
                        child: Text(request.status, style: TextStyle(
                          color: request.status == 'ACTIVE' ? AppColors.primary : Colors.grey.shade600,
                          fontSize: 10, fontWeight: FontWeight.w900
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(request.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
                        child: Row(
                          children: [
                            const Icon(Icons.handshake_rounded, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('$offerCount offers', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blue)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time_filled, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text('Needed by ${request.neededBy ?? 'ASAP'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
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
}
