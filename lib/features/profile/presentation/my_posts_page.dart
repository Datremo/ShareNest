import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
          .select('*, requests(id)')
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
            _listingRequestCounts[l['id']] = (l['requests'] as List).length;
          }

          _myUrgentRequests = [];
          _urgentOfferCounts = {};
          for (var u in urgentRes) {
            _myUrgentRequests.add(UrgentRequest.fromJson(u));
            _urgentOfferCounts[u['id']] = (u['urgent_request_offers'] as List).length;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text('My Posts', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 22)),
            Text('Manage your listings & requests', style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey[500],
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          tabs: const [
            Tab(text: 'Listings'),
            Tab(text: 'Need It Now'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListingsTab(),
                _buildUrgentTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/create_lend_post').then((_) => _fetchRealData());
          } else {
            context.push('/create_urgent_request').then((_) => _fetchRealData());
          }
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'New Listing' : 'New Urgent Request',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildListingsTab() {
    return Column(
      children: [
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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _filteredListings.length,
                  itemBuilder: (context, index) => _buildListingCard(_filteredListings[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildUrgentTab() {
    return _myUrgentRequests.isEmpty
        ? _buildEmptyState('No urgent requests found', Icons.bolt_rounded)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: _myUrgentRequests.length,
            itemBuilder: (context, index) => _buildUrgentCard(_myUrgentRequests[index]),
          );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[200]),
            child: Icon(icon, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildListingCard(Listing listing) {
    Color badgeColor = listing.mode.toUpperCase() == 'LEND' ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final hasImage = listing.photoUrls.isNotEmpty;
    final reqCount = _listingRequestCounts[listing.id] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/item', extra: listing).then((_) => _fetchRealData()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
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
                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(listing.mode.toUpperCase(), style: GoogleFonts.inter(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: listing.status == 'ACTIVE' ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(6)
                          ),
                          child: Text(listing.status, style: GoogleFonts.inter(
                            color: listing.status == 'ACTIVE' ? const Color(0xFF10B981) : Colors.grey[600],
                            fontSize: 10, fontWeight: FontWeight.bold
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(listing.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('$reqCount requests', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text(DateFormat('MMM d').format(listing.createdAt ?? DateTime.now()), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Text('NEED IT NOW', style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: request.status == 'ACTIVE' ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6)
                    ),
                    child: Text(request.status, style: GoogleFonts.inter(
                      color: request.status == 'ACTIVE' ? const Color(0xFF10B981) : Colors.grey[600],
                      fontSize: 10, fontWeight: FontWeight.bold
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(request.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('$offerCount offers', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time_filled, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('Needed by ${request.neededBy ?? 'ASAP'}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
