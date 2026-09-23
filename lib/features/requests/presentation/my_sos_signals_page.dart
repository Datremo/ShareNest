import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';

class UnifiedRequest {
  final String id;
  final String type; // 'Lend', 'Give', 'Urgent'
  final String title;
  final String description;
  final DateTime createdAt;
  final String status;
  final String? imageUrl;
  final String locationName;
  final String partnerName;
  final String? partnerAvatar;
  final bool isPostedByMe;
  final String? requestId;

  UnifiedRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
    this.imageUrl,
    required this.locationName,
    required this.partnerName,
    this.partnerAvatar,
    required this.isPostedByMe,
    this.requestId,
  });
}

class MySosSignalsPage extends StatefulWidget {
  const MySosSignalsPage({super.key});

  @override
  State<MySosSignalsPage> createState() => _MySosSignalsPageState();
}

class _MySosSignalsPageState extends State<MySosSignalsPage> {
  bool _isLoading = true;
  List<UnifiedRequest> _allRequests = [];
  String _selectedTab = 'Posted by me';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    List<UnifiedRequest> temp = [];

    // 1. URGENT REQUESTS POSTED BY ME
    try {
      final urgentRes = await Supabase.instance.client
          .from('urgent_requests')
          .select('*, profiles:requester_id(*)')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      for (var u in urgentRes) {
        temp.add(UnifiedRequest(
          id: u['id'],
          type: 'Urgent',
          title: u['title'] ?? 'Urgent Request',
          description: u['description'] ?? 'Need it as soon as possible.',
          createdAt: u['created_at'] != null ? DateTime.parse(u['created_at']) : DateTime.now(),
          status: u['status'] ?? 'ACTIVE',
          imageUrl: u['image_url'],
          locationName: u['profiles'] != null ? u['profiles']['location_name'] ?? 'Nearby' : 'Nearby',
          partnerName: u['profiles'] != null ? u['profiles']['full_name'] ?? 'Me' : 'Me',
          partnerAvatar: u['profiles'] != null ? u['profiles']['avatar_url'] : null,
          isPostedByMe: true,
          requestId: u['id'],
        ));
      }
    } catch (e) {
      debugPrint('Error fetching urgent requests: $e');
    }

    // 2. ITEM REQUESTS POSTED BY ME (I requested someone else's item)
    try {
      final itemsRequestedRes = await Supabase.instance.client
          .from('item_requests')
          .select('*, listings!inner(*, profiles:owner_id(*))')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      for (var req in itemsRequestedRes) {
        final listing = req['listings'];
        final ownerProfile = listing['profiles'];
        String type = listing['mode'] == 'GIVE' ? 'Give' : 'Lend';
        if (listing['title'].toString().contains('SOS Fulfillment')) type = 'Urgent';

        temp.add(UnifiedRequest(
          id: listing['id'],
          type: type,
          title: listing['title'] ?? 'Listing',
          description: listing['description'] ?? 'Requested item',
          createdAt: req['created_at'] != null ? DateTime.parse(req['created_at']) : DateTime.now(),
          status: req['status'] ?? 'PENDING',
          imageUrl: (listing['photo_urls'] != null && (listing['photo_urls'] as List).isNotEmpty) 
              ? listing['photo_urls'][0] 
              : null,
          locationName: ownerProfile != null ? ownerProfile['location_name'] ?? 'Nearby' : 'Nearby',
          partnerName: ownerProfile != null ? ownerProfile['full_name'] ?? 'Neighbor' : 'Neighbor',
          partnerAvatar: ownerProfile != null ? ownerProfile['avatar_url'] : null,
          isPostedByMe: true,
          requestId: req['id'],
        ));
      }
    } catch (e) {
      debugPrint('Error fetching item requests posted by me: $e');
    }

    // 3. REQUESTS SOLVED BY ME (People requesting my items)
    try {
      final itemsSolvedRes = await Supabase.instance.client
          .from('item_requests')
          .select('*, listings!inner(*), requester:profiles!item_requests_requester_id_fkey(*)')
          .eq('listings.owner_id', userId)
          .order('created_at', ascending: false);

      for (var req in itemsSolvedRes) {
        final listing = req['listings'];
        final requester = req['requester'];
        String type = listing['mode'] == 'GIVE' ? 'Give' : 'Lend';
        if (listing['title'].toString().contains('SOS Fulfillment')) type = 'Urgent';

        temp.add(UnifiedRequest(
          id: listing['id'],
          type: type,
          title: listing['title'] ?? 'Listing',
          description: listing['description'] ?? 'My listing',
          createdAt: req['created_at'] != null ? DateTime.parse(req['created_at']) : DateTime.now(),
          status: req['status'] ?? 'PENDING',
          imageUrl: (listing['photo_urls'] != null && (listing['photo_urls'] as List).isNotEmpty) 
              ? listing['photo_urls'][0] 
              : null,
          locationName: requester != null ? requester['location_name'] ?? 'Nearby' : 'Nearby',
          partnerName: requester != null ? requester['full_name'] ?? 'Neighbor' : 'Neighbor',
          partnerAvatar: requester != null ? requester['avatar_url'] : null,
          isPostedByMe: false,
          requestId: req['id'],
        ));
      }
    } catch (e) {
      debugPrint('Error fetching items solved by me: $e');
    }

    temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _allRequests = temp;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postedByMe = _allRequests.where((r) => r.isPostedByMe).toList();
    final solvedByMe = _allRequests.where((r) => !r.isPostedByMe).toList();
    
    final currentList = _selectedTab == 'Posted by me' ? postedByMe : solvedByMe;
    final filteredList = currentList.where((r) {
      if (_selectedFilter == 'All') return true;
      return r.type == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]),
              child: const Icon(CupertinoIcons.back, color: Colors.black87, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sunset_balcony.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.9)],
              stops: const [0.0, 0.4],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Live Requests', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF064B34))),
                      const SizedBox(height: 8),
                      Text('Track what you need and see\nhow you\'re helping your neighbours.', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4A6B5D))),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Segmented Control
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildSegmentButton('Posted by me', postedByMe.length, Icons.near_me_outlined)),
                        Expanded(child: _buildSegmentButton('Solved by me', solvedByMe.length, CupertinoIcons.heart)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildFilterChip('All', currentList.length, null, null),
                      _buildFilterChip('Lend', currentList.where((r) => r.type == 'Lend').length, Icons.bolt, const Color(0xFFFF4B4B)),
                      _buildFilterChip('Give', currentList.where((r) => r.type == 'Give').length, Icons.calendar_today, const Color(0xFF34C759)),
                      _buildFilterChip('Urgent', currentList.where((r) => r.type == 'Urgent').length, Icons.near_me, const Color(0xFFFF9500)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // List
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF064B34)))
                      : filteredList.isEmpty
                          ? Center(child: Text('No requests found.', style: GoogleFonts.inter(color: Colors.grey[600])))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                return _buildRequestCard(filteredList[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String title, int count, IconData icon) {
    bool isSelected = _selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = title;
        _selectedFilter = 'All'; // reset filter
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF064B34) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, IconData? icon, Color? iconColor) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF064B34) : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF064B34) : Colors.white, width: 2),
          boxShadow: [if (!isSelected) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: isSelected ? Colors.white : iconColor), const SizedBox(width: 6)],
            Text('$label ($count)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(UnifiedRequest req) {
    Color tagColor;
    IconData tagIcon;
    if (req.type == 'Urgent') {
      tagColor = const Color(0xFFFF4B4B);
      tagIcon = Icons.near_me;
    } else if (req.type == 'Give') {
      tagColor = const Color(0xFF34C759);
      tagIcon = Icons.calendar_today;
    } else {
      tagColor = const Color(0xFFFF9500);
      tagIcon = Icons.bolt;
    }

    return GestureDetector(
      onTap: () {
        if (req.type == 'Urgent' && req.requestId != null && req.isPostedByMe) {
          context.push('/urgent_request_detail/${req.requestId}');
        } else if (req.requestId != null) {
          if (req.isPostedByMe) {
            context.push('/requester-request-detail/${req.requestId}');
          } else {
            context.push('/owner-request-detail/${req.requestId}');
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: tagColor.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2),
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail with Tag
              Container(
                width: 110, height: 130,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: req.imageUrl != null ? DecorationImage(image: NetworkImage(req.imageUrl!), fit: BoxFit.cover) : null,
                ),
                child: Stack(
                  children: [
                    if (req.imageUrl == null) const Center(child: Icon(Icons.image, color: Colors.grey)),
                    // Tag overlay
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tagIcon, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(req.type, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    // Photo count overlay
                    Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('Photos', style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(req.title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text(timeago.format(req.createdAt), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFFF4B4B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(req.description, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF1E293B)),
                        const SizedBox(width: 4),
                        Expanded(child: Text('2.1 km away · ${req.locationName}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E293B), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: req.partnerAvatar != null ? NetworkImage(req.partnerAvatar!) : null,
                          backgroundColor: Colors.grey[300],
                          child: req.partnerAvatar == null ? Text(req.partnerName[0], style: const TextStyle(fontSize: 10, color: Colors.grey)) : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(req.partnerName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5E5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_rounded, size: 12, color: Color(0xFFFF4B4B)),
                              const SizedBox(width: 6),
                              Text('Chat', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF4B4B))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFFF4B4B)),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
