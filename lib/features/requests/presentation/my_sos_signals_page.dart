import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class UnifiedUrgentRequest {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String status;
  final String? imageUrl;
  final String locationName;
  final String partnerName;
  final String? partnerAvatar;
  final bool isPostedByMe; // True if "I Need", False if "I Helped"
  final String? requestId;
  final String? offerId;
  final List<Map<String, dynamic>> offers;

  UnifiedUrgentRequest({
    required this.id,
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
    this.offerId,
    this.offers = const [],
  });
}

class MySosSignalsPage extends StatefulWidget {
  const MySosSignalsPage({super.key});

  @override
  State<MySosSignalsPage> createState() => _MySosSignalsPageState();
}

class _MySosSignalsPageState extends State<MySosSignalsPage> {
  bool _isLoading = true;
  List<UnifiedUrgentRequest> _allRequests = [];
  String _selectedTab = 'I Need';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    List<UnifiedUrgentRequest> temp = [];

    // 1. I NEED: Urgent requests posted by me
    try {
      final urgentRes = await Supabase.instance.client
          .from('urgent_requests')
          .select(
            '*, profiles:requester_id(*), urgent_request_offers(*, profiles:helper_id(*))',
          )
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      for (var u in urgentRes) {
        temp.add(
          UnifiedUrgentRequest(
            id: u['id'],
            title: u['title'] ?? 'Urgent Request',
            description: u['description'] ?? 'Need it as soon as possible.',
            createdAt: u['created_at'] != null
                ? DateTime.parse(u['created_at'])
                : DateTime.now(),
            status: u['status'] ?? 'OPEN',
            imageUrl: u['image_url'],
            locationName: u['profiles'] != null
                ? u['profiles']['location_name'] ?? 'Nearby'
                : 'Nearby',
            partnerName: 'Me',
            partnerAvatar: u['profiles'] != null
                ? u['profiles']['avatar_url']
                : null,
            isPostedByMe: true,
            requestId: u['id'],
            offers: List<Map<String, dynamic>>.from(
              u['urgent_request_offers'] ?? [],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching urgent requests: \$e');
    }

    // 2. I HELPED: Urgent offers made by me that are ACCEPTED or COMPLETED
    try {
      final offersMade = await Supabase.instance.client
          .from('urgent_request_offers')
          .select('*, urgent_requests(*, profiles:requester_id(*))')
          .eq('helper_id', userId)
          .inFilter('status', ['ACCEPTED', 'COMPLETED'])
          .order('created_at', ascending: false);

      for (var o in offersMade) {
        final req = o['urgent_requests'];
        final requester = req['profiles'];
        
        temp.add(
          UnifiedUrgentRequest(
            id: req['id'],
            title: req['title'] ?? 'Urgent Request',
            description: req['description'] ?? 'Need it as soon as possible.',
            createdAt: o['created_at'] != null
                ? DateTime.parse(o['created_at'])
                : DateTime.now(),
            status: o['status'] ?? 'ACCEPTED', 
            imageUrl: req['image_url'],
            locationName: requester != null
                ? requester['location_name'] ?? 'Nearby'
                : 'Nearby',
            partnerName: requester != null
                ? requester['full_name'] ?? 'Neighbor'
                : 'Neighbor',
            partnerAvatar: requester != null ? requester['avatar_url'] : null,
            isPostedByMe: false, // I am the helper
            requestId: req['id'], 
            offerId: o['id'],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching urgent offers made by me: \$e');
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
    final iNeedList = _allRequests.where((r) => r.isPostedByMe).toList();
    final iHelpedList = _allRequests.where((r) => !r.isPostedByMe).toList();

    final currentList = _selectedTab == 'I Need' ? iNeedList : iHelpedList;

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
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.black87,
                size: 20,
              ),
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
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.9),
              ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Urgent Requests',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF064B34),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track what you need and see\nhow you\'re helping your neighbours.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF4A6B5D),
                        ),
                      ),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            'I Need',
                            iNeedList.length,
                            Icons.near_me_outlined,
                          ),
                        ),
                        Expanded(
                          child: _buildSegmentButton(
                            'I Helped',
                            iHelpedList.length,
                            CupertinoIcons.heart,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF064B34),
                          ),
                        )
                      : currentList.isEmpty
                      ? Center(
                          child: Text(
                            'No urgent requests found.',
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(currentList[index]);
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
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '\$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(UnifiedUrgentRequest req) {
    Color tagColor = const Color(0xFFFF4B4B); // Red for urgent
    IconData tagIcon = Icons.near_me;
    
    // Status text formatting
    String statusText = req.status.toUpperCase();
    if (req.isPostedByMe && req.status == 'OPEN' && req.offers.isNotEmpty) {
      statusText = 'WAITING FOR OFFERS';
    }

    return GestureDetector(
      onTap: () async {
        if (req.requestId != null && req.isPostedByMe) {
          context.push('/urgent_request_detail/${req.requestId}');
        } else if (req.offerId != null) {
          // Find the transaction (item_request) generated from this offer's listing
          try {
            final offerRes = await Supabase.instance.client
                .from('urgent_request_offers')
                .select('offered_listing_id')
                .eq('id', req.offerId!)
                .single();
                
            final listingId = offerRes['offered_listing_id'];
            if (listingId != null) {
                final itemReqRes = await Supabase.instance.client
                    .from('item_requests')
                    .select('id')
                    .eq('listing_id', listingId)
                    .limit(1)
                    .maybeSingle();
                    
                if (itemReqRes != null) {
                    context.push('/owner-request-detail/${itemReqRes['id']}');
                    return;
                }
            }
          } catch(e) {
            debugPrint('Error finding transaction: $e');
          }
          // Fallback if transaction isn't found
          context.push('/offer_detail/${req.offerId}');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: tagColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Thumbnail with Tag
                  Container(
                    width: 110,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      image: req.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(req.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        if (req.imageUrl == null)
                          const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        // Tag overlay
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tagIcon, size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'URGENT',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                              child: Text(
                                req.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeago.format(req.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFFFF4B4B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          req.description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Color(0xFF1E293B),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                req.locationName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: req.partnerAvatar != null
                                  ? NetworkImage(req.partnerAvatar!)
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: req.partnerAvatar == null
                                  ? Text(
                                      req.partnerName[0],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                req.partnerName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: req.status == 'ACCEPTED' || req.status == 'COMPLETED' 
                                    ? const Color(0xFFE5F9ED)
                                    : const Color(0xFFFFE5E5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: req.status == 'ACCEPTED' || req.status == 'COMPLETED' 
                                      ? const Color(0xFF064B34)
                                      : const Color(0xFFFF4B4B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (req.isPostedByMe && req.offers.isNotEmpty && req.status == 'OPEN') ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.black12, height: 1),
                const SizedBox(height: 12),
                Text(
                  'Incoming Offers (${req.offers.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                ...req.offers.map((offer) => _buildOfferTile(req, offer)),
              ],
            ],
          ), // closes Column
        ), // closes Padding
      ), // closes Container
    ); // closes GestureDetector
  }

  Widget _buildOfferTile(UnifiedUrgentRequest req, Map<String, dynamic> offer) {
    final helper = offer['profiles'] ?? {};
    final helperName = helper['full_name'] ?? 'Neighbour';
    final helperAvatar = helper['avatar_url'];
    final mode = offer['mode'] ?? 'LEND';
    final duration = offer['available_for_duration'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (helper['id'] != null) {
                context.push('/user_profile?userId=${helper["id"]}');
              }
            },
            child: CircleAvatar(
              radius: 16,
              backgroundImage: helperAvatar != null
                  ? NetworkImage(helperAvatar)
                  : null,
              backgroundColor: Colors.grey[300],
              child: helperAvatar == null
                  ? Text(
                      helperName[0],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helperName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Offers to \$mode (\$duration)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _declineOffer(offer['id']),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Decline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _acceptOffer(offer['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B4B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _declineOffer(String offerId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      await Supabase.instance.client
          .from('urgent_request_offers')
          .update({'status': 'REJECTED'})
          .eq('id', offerId);

      if (mounted) {
        context.pop(); // dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Offer declined.')));
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to decline: \$e')));
      }
    }
  }

  Future<void> _acceptOffer(String offerId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final reqId = await Supabase.instance.client.rpc(
        'accept_urgent_offer',
        params: {'p_offer_id': offerId},
      );

      if (mounted) {
        context.pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer Accepted! Starting transaction...'),
          ),
        );
        _loadData();
      }
    } catch (e) {
      debugPrint('Error accepting offer: \$e');
      if (mounted) {
        context.pop(); // dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept: \$e')));
      }
    }
  }
}
