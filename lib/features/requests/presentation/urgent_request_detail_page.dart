import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/urgent_request.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

class UrgentRequestDetailPage extends StatefulWidget {
  final String requestId;

  const UrgentRequestDetailPage({super.key, required this.requestId});

  @override
  State<UrgentRequestDetailPage> createState() => _UrgentRequestDetailPageState();
}

class _UrgentRequestDetailPageState extends State<UrgentRequestDetailPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  UrgentRequest? _request;
  Map<String, dynamic>? _requesterProfile;
  bool _isOffering = false;
  List<Map<String, dynamic>> _offers = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadRequest();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    if (_request == null) return;
    try {
      final data = await Supabase.instance.client
          .from('urgent_request_offers')
          .select('*, profiles!urgent_request_offers_helper_id_fkey(*)')
          .eq('urgent_request_id', widget.requestId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error loading offers: $e');
    }
  }

  Future<void> _loadRequest() async {
    try {
      final data = await Supabase.instance.client
          .from('urgent_requests')
          .select('*, profiles(*)')
          .eq('id', widget.requestId)
          .single();
      
      if (mounted) {
        setState(() {
          _request = UrgentRequest.fromJson(data);
          _requesterProfile = data['profiles'] as Map<String, dynamic>;
          _isLoading = false;
        });
        _loadOffers();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _offerHelp(String type, String duration, {String? listingId}) async {
    setState(() => _isOffering = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (_request?.requesterId == user.id) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot help yourself!')));
        return;
      }

      String? finalListingId = listingId;
      
      if (finalListingId == null) {
        final newListing = await Supabase.instance.client.from('listings').insert({
          'owner_id': user.id,
          'title': _request!.title,
          'mode': type.toUpperCase(),
          'category_id': 'urgent_category',
          'description': 'Urgent fulfillment for: ${_request!.title}',
          'status': 'ACTIVE',
          'is_urgent_fulfillment': true,
        }).select('id').single();
        finalListingId = newListing['id'] as String;
      }

      await Supabase.instance.client.from('urgent_request_offers').insert({
        'urgent_request_id': widget.requestId,
        'helper_id': user.id,
        'available_for_duration': duration,
        'status': 'PENDING',
        'mode': type.toUpperCase(),
        'offered_listing_id': finalListingId,
      });

      if (mounted) {
        context.pop(); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer sent! The requester will be notified.')),
        );
        _loadOffers(); // reload offers instead of popping the page
      }

    } catch (e) {
      debugPrint('Error offering help: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Oops!'),
            content: Text('Failed to send offer: $e'),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOffering = false);
    }
  }

  Future<void> _acceptOffer(String offerId, String helperId, String mode, String? offeredListingId) async {
    try {
      final supabase = Supabase.instance.client;
      if (offeredListingId == null) throw Exception("Offer is missing a listing ID");

      await supabase.from('item_requests').insert({
        'listing_id': offeredListingId,
        'requester_id': _request!.requesterId,
        'status': 'ACCEPTED',
        'is_urgent': true,
        'message': 'Urgent Request Accepted',
        'duration': _request!.duration,
      });

      await supabase.from('urgent_request_offers').update({'status': 'ACCEPTED'}).eq('id', offerId);
      await supabase.from('urgent_requests').update({'status': 'COMPLETED'}).eq('id', widget.requestId);
      await supabase.from('urgent_request_offers').update({'status': 'DECLINED'}).eq('urgent_request_id', widget.requestId).neq('id', offerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer accepted! Check your activity/dashboard.')));
        context.pop(); 
      }
    } catch (e) {
      debugPrint('Error accepting offer: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showOfferBottomSheet() {
    String selectedDuration = '2 hours';
    String selectedType = 'lend'; 
    String? selectedListingId;
    List<dynamic> myListings = [];
    bool isLoadingListings = true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final options = ['30 min', '1 hour', '2 hours', '1 day'];

            if (isLoadingListings) {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                Supabase.instance.client
                    .from('listings')
                    .select('id, title, type, image_url')
                    .eq('owner_id', user.id)
                    .eq('status', 'ACTIVE')
                    .then((res) {
                  if (mounted) setModalState(() { myListings = res; isLoadingListings = false; });
                }).catchError((e) {
                  if (mounted) setModalState(() => isLoadingListings = false);
                });
              } else {
                isLoadingListings = false;
              }
            }

            return Container(
              padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Text('How can you help?', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Text('Choose how you want to fulfill this request.', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'lend'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: selectedType == 'lend' ? const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFE53935)]) : null,
                                color: selectedType == 'lend' ? null : Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selectedType == 'lend' ? Colors.transparent : Colors.grey[200]!),
                                boxShadow: selectedType == 'lend' ? [BoxShadow(color: const Color(0xFFE53935).withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.handshake_outlined, color: selectedType == 'lend' ? Colors.white : const Color(0xFF64748B)),
                                    const SizedBox(height: 8),
                                    Text('Lend It', style: GoogleFonts.inter(color: selectedType == 'lend' ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => selectedType = 'give'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: selectedType == 'give' ? const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFE53935)]) : null,
                                color: selectedType == 'give' ? null : Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selectedType == 'give' ? Colors.transparent : Colors.grey[200]!),
                                boxShadow: selectedType == 'give' ? [BoxShadow(color: const Color(0xFFE53935).withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.favorite_outline, color: selectedType == 'give' ? Colors.white : const Color(0xFF64748B)),
                                    const SizedBox(height: 8),
                                    Text('Give It', style: GoogleFonts.inter(color: selectedType == 'give' ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => setModalState(() => selectedType = 'listing'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: selectedType == 'listing' ? const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6366F1)]) : null,
                          color: selectedType == 'listing' ? null : Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selectedType == 'listing' ? Colors.transparent : Colors.grey[200]!),
                          boxShadow: selectedType == 'listing' ? [BoxShadow(color: const Color(0xFF4338CA).withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined, color: selectedType == 'listing' ? Colors.white : const Color(0xFF64748B)),
                              const SizedBox(width: 12),
                              Text('Offer from My Listings', style: GoogleFonts.inter(color: selectedType == 'listing' ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (selectedType == 'lend') ...[
                      Text('Duration', style: GoogleFonts.inter(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: options.map((opt) => GestureDetector(
                          onTap: () => setModalState(() => selectedDuration = opt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            decoration: BoxDecoration(
                              color: selectedDuration == opt ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selectedDuration == opt ? Colors.transparent : Colors.grey[300]!),
                            ),
                            child: Text(opt, style: TextStyle(color: selectedDuration == opt ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          ),
                        )).toList(),
                      ),
                    ] else if (selectedType == 'give') ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha:0.5))),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                              child: const Icon(Icons.favorite, color: Color(0xFFEF4444)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text('You are amazing! This item will be permanently transferred. No return needed.', style: GoogleFonts.inter(color: const Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      if (isLoadingListings)
                        const Center(child: CircularProgressIndicator())
                      else if (myListings.isEmpty)
                        Text('You have no active listings to offer.', style: GoogleFonts.inter(color: Colors.grey[600]))
                      else
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: myListings.length,
                            itemBuilder: (ctx, i) {
                              final list = myListings[i];
                              final isSel = selectedListingId == list['id'];
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedListingId = list['id']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 130,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSel ? const Color(0xFF4338CA) : Colors.grey[200]!, width: isSel ? 2 : 1),
                                    boxShadow: isSel ? [BoxShadow(color: const Color(0xFF4338CA).withValues(alpha:0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                          child: list['image_url'] != null
                                              ? Image.network(list['image_url'], fit: BoxFit.cover)
                                              : Container(color: Colors.grey[50], child: const Icon(Icons.image, color: Colors.grey)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(list['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1E293B))),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isOffering || (selectedType == 'listing' && selectedListingId == null))
                            ? null
                            : () {
                                final mode = selectedType == 'listing' 
                                  ? (myListings.firstWhere((l) => l['id'] == selectedListingId)['type'] == 'GIVE' ? 'give' : 'lend')
                                  : selectedType;
                                _offerHelp(
                                  mode, 
                                  mode == 'lend' ? selectedDuration : 'forever', 
                                  listingId: selectedListingId
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: _isOffering
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text('Send Offer', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))));
    }
    if (_request == null) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: Text('Request not found')));
    }

    final req = _request!;
    final name = _requesterProfile?['display_name'] ?? 'Neighbour';
    final avatar = _requesterProfile?['avatar_url'];
    final currentUser = Supabase.instance.client.auth.currentUser?.id;
    final hasOffered = _offers.any((o) => o['helper_id'] == currentUser && (o['status'] == 'PENDING' || o['status'] == 'ACCEPTED'));
    final isRequester = req.requesterId == currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.3), shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Deep rich gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Abstract circles for decoration
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE53935).withValues(alpha:0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    left: -50,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4338CA).withValues(alpha:0.15),
                      ),
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha:0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha:0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt_rounded, color: Color(0xFFFCA5A5), size: 16),
                                    const SizedBox(width: 6),
                                    Text('NEED IT NOW', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('~400m away', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(req.title, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                          if (req.description != null && req.description!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(req.description!, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[300], height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Requester Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          backgroundColor: Colors.grey[200],
                          child: avatar == null ? Text(name[0], style: const TextStyle(color: Colors.grey, fontSize: 24)) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Requested by', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                          child: const Icon(Icons.message_rounded, color: Color(0xFF64748B), size: 20),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Details Grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.access_time_filled, color: Color(0xFF6366F1), size: 20),
                                ),
                                const SizedBox(height: 16),
                                Text('Needed by', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(req.neededBy ?? 'Right now', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[100]!)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.timer, color: Color(0xFFF59E0B), size: 20),
                                ),
                                const SizedBox(height: 16),
                                Text('Duration', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(req.duration ?? '30 min', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    if (isRequester) ...[
                      Text('Neighbour Responses', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 16),
                      if (_offers.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.radar, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Waiting for neighbours...', style: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _offers.length,
                          itemBuilder: (ctx, i) {
                            final offer = _offers[i];
                            final helper = offer['profiles'] as Map<String, dynamic>?;
                            final status = offer['status'] as String;
                            final isAccepted = status == 'ACCEPTED';
                            final isDeclined = status == 'DECLINED' || status == 'REJECTED';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isAccepted ? const Color(0xFFF0FDF4) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: isAccepted ? const Color(0xFF86EFAC) : Colors.grey[200]!),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: helper?['avatar_url'] != null ? NetworkImage(helper!['avatar_url']) : null,
                                    backgroundColor: Colors.grey[100],
                                    child: helper?['avatar_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(helper?['display_name'] ?? 'Neighbour', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B))),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(offer['mode'] == 'GIVE' ? Icons.favorite : Icons.handshake, size: 14, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(offer['mode'] == 'GIVE' ? 'Wants to Give' : 'Wants to Lend', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (req.status == 'ACTIVE' && !isAccepted && !isDeclined)
                                    ElevatedButton(
                                      onPressed: () => _acceptOffer(offer['id'], offer['helper_id'], offer['mode'], offer['offered_listing_id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1E293B),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        elevation: 0,
                                      ),
                                      child: Text('Accept', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isAccepted ? const Color(0xFFDCFCE7) : (isDeclined ? const Color(0xFFFEE2E2) : Colors.grey[100]),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: GoogleFonts.inter(
                                          color: isAccepted ? const Color(0xFF166534) : (isDeclined ? const Color(0xFF991B1B) : Colors.grey[600]),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                        )
                                      ),
                                    )
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                    
                    const SizedBox(height: 100), // padding for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: (!isRequester && req.status == 'ACTIVE') ? Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: hasOffered 
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                  const SizedBox(width: 12),
                  Text('Offer Sent! Waiting for response', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
                ],
              ),
            )
          : AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.02),
                  child: ElevatedButton(
                    onPressed: _showOfferBottomSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 10,
                      shadowColor: const Color(0xFFEF4444).withValues(alpha:0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text('I Can Help', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                );
              }
            ),
        ),
      ) : null,
    );
  }
}
