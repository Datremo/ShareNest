import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/models/urgent_request.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/data/repositories/chat_repository.dart';
import '../../messages/presentation/conversation_page.dart';

class UrgentRequestDetailPage extends StatefulWidget {
  final String requestId;
  final bool openOffer;

  const UrgentRequestDetailPage({super.key, required this.requestId, this.openOffer = false});

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
  geo.Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadRequest();
    _fetchLocation();
    
    if (widget.openOffer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait a small delay to ensure UI and data is ready before showing bottom sheet
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _request != null) {
            _showOfferBottomSheet();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;
      
      final pos = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.high);
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
  }

  String _getDistanceText() {
    if (_currentPosition != null && _request?.lat != null && _request?.lng != null) {
      double dist = geo.Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude,
        _request!.lat!, _request!.lng!
      );
      if (dist < 1000) return '~${dist.round()} m away';
      return '~${(dist/1000).toStringAsFixed(1)} km away';
    }
    return '~${_request?.radiusKm?.toStringAsFixed(1) ?? '2.0'} km away';
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

  Future<void> _offerHelp(String type, String duration, {String? listingId, String? windowStart, String? windowEnd, String? extraDetails, String? handoverLocation, String? handoverMethod}) async {
    setState(() => _isOffering = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (_request?.requesterId == user.id) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot help yourself!')));
        return;
      }

      String finalListingId = listingId ?? '';
      if (finalListingId.isEmpty) {
        final newListing = await Supabase.instance.client.from('listings').insert({
          'owner_id': user.id,
          'title': _request?.title ?? 'Urgent Request Fulfillment',
          'description': 'Offer details: ${extraDetails ?? ''}',
          'mode': type.toUpperCase(),
          'category_id': 'urgent_category',
          'status': 'UNAVAILABLE',
          'is_urgent_fulfillment': true,
        }).select('id').single();
        finalListingId = newListing['id'] as String;
      }

      final jsonPayload = jsonEncode({
        'duration': duration,
        'type': type.toUpperCase(),
        'listing_id': finalListingId,
        'extra_details': extraDetails ?? '',
        'handover_location': handoverLocation ?? '',
        'handover_method': handoverMethod ?? '',
      });

      await Supabase.instance.client.from('urgent_request_offers').insert({
        'urgent_request_id': widget.requestId,
        'helper_id': user.id,
        'available_for_duration': jsonPayload,
        'status': 'PENDING',
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
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // CALL THE BACKEND RPC THAT HANDLES EVERYTHING ROBUSTLY
      final response = await supabase.rpc(
        'accept_urgent_offer',
        params: {'p_offer_id': offerId},
      );
      
      final String newItemReqId = response as String;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted! Check your chat / dashboard.')),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Error accepting offer: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteRequest() async {
    try {
      // Offers will be deleted automatically if there's a CASCADE ON DELETE foreign key, 
      // but if not, we should probably delete them first or just let Supabase handle it if configured.
      await Supabase.instance.client.from('urgent_requests').delete().eq('id', widget.requestId);
      if (mounted) {
        context.pop(); // go back to map/list
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Urgent request deleted.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting request: $e')));
    }
  }

  void _confirmDeleteRequest() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request?'),
        content: const Text('Are you sure you want to delete this urgent request? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ctx.pop();
              _deleteRequest();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOffer(String offerId) async {
    try {
      await Supabase.instance.client.from('urgent_request_offers').delete().eq('id', offerId);
      if (mounted) {
        context.pop(); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer deleted.')));
        _loadOffers();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting offer: $e')));
    }
  }

  void _confirmDeleteOffer(String offerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: const Text('Are you sure you want to delete your offer?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ctx.pop();
              _deleteOffer(offerId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showOfferDetailsDialog(Map<String, dynamic> offer, String offerType, String listingId, bool isAccepted, bool isDeclined) {
    final helper = offer['profiles'] as Map<String, dynamic>?;
    final status = offer['status'] as String;
    
    Map<String, dynamic> offerData = {};
    try {
      offerData = jsonDecode(offer['available_for_duration'] as String? ?? '{}');
    } catch (_) {}

    final extraDetails = offerData['extra_details'] as String? ?? 'No extra details';
    final handoverLocation = offerData['handover_location'] as String? ?? 'N/A';
    final handoverMethod = offerData['handover_method'] as String? ?? 'N/A';
    final photos = offerData['photos'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
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
                          Text(helper?['display_name'] ?? 'Neighbour', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B))),
                          Text(offerType == 'GIVE' ? 'Wants to Give' : 'Wants to Lend', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                      onPressed: () async {
                        try {
                          final currentUser = Supabase.instance.client.auth.currentUser;
                          if (currentUser == null) return;
                          
                          final isRequester = currentUser.id == _request?.requesterId;
                          final otherUserId = isRequester ? offer['helper_id'] : _request!.requesterId;
                          
                          String? otherUserName;
                          if (isRequester) {
                            otherUserName = helper != null ? helper['display_name'] : null;
                          } else {
                            otherUserName = _requesterProfile != null ? _requesterProfile!['display_name'] : null;
                          }

                          final chatRepo = ChatRepository();
                          final convId = await chatRepo.createOrGetConversation(
                            contextType: 'urgent_offer',
                            contextId: offer['id'],
                            otherUserId: otherUserId,
                          );
                          
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ConversationPage(
                                  conversationId: convId ?? '',
                                  otherUserName: otherUserName ?? 'Neighbor',
                                  contextLabel: 'Context: Urgent Request - ${_request?.title}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                if (photos.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, idx) {
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(photos[idx]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text('Message & Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(extraDetails, style: GoogleFonts.inter(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[500], size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(handoverLocation, style: GoogleFonts.inter(color: Colors.black87, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.handshake, color: Colors.grey[500], size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(handoverMethod, style: GoogleFonts.inter(color: Colors.black87, fontSize: 14))),
                  ],
                ),

                const SizedBox(height: 32),
                if (_request?.status == 'ACTIVE' && !isAccepted && !isDeclined)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _acceptOffer(offer['id'], offer['helper_id'], offerType, listingId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534), // Dark Green for big CTA
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: Text('Accept Offer', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 16),
                
                if (offer['helper_id'] == Supabase.instance.client.auth.currentUser?.id && !isAccepted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _confirmDeleteOffer(offer['id']);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: Text('Delete My Offer', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }

  void _showOfferBottomSheet() {
    String selectedType = 'lend'; 
    String? selectedListingId;
    DateTime? startDate;
    DateTime? endDate;
    List<dynamic> myListings = [];
    bool isLoadingListings = true;
    
    final TextEditingController detailsController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController methodController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                child: SingleChildScrollView(
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
                    
                    if (selectedType == 'lend' || selectedType == 'give') ...[
                      Text(selectedType == 'lend' ? 'Availability Period' : 'Available From', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                        title: Text(startDate == null ? 'Select Start Date & Time' : startDate.toString().substring(0,16)),
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (d != null) {
                            final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (t != null) {
                              setModalState(() {
                                startDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                              });
                            }
                          }
                        },
                      ),
                      if (selectedType == 'lend')
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_busy, color: Color(0xFFEF4444)),
                          title: Text(endDate == null ? 'Select End Date & Time' : endDate.toString().substring(0,16)),
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: startDate ?? DateTime.now(), firstDate: startDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (d != null) {
                              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (t != null) {
                                setModalState(() {
                                  endDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                                });
                              }
                            }
                          },
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
                    
                    const SizedBox(height: 24),
                    Text('Extra Details (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsController,
                      decoration: InputDecoration(
                        hintText: 'Any message or details for the requester?',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        hintText: 'Handover Location (e.g. My porch, Park)',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: methodController,
                      decoration: InputDecoration(
                        hintText: 'Handover Method (e.g. In-person, Drop-off)',
                        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.handshake, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isOffering || 
                                        (selectedType == 'listing' && selectedListingId == null) ||
                                        (selectedType == 'give' && startDate == null) ||
                                        (selectedType == 'lend' && (startDate == null || endDate == null)))
                                ? null
                                : () {
                                    if (selectedType == 'listing') {
                                      final mode = (myListings.firstWhere((l) => l['id'] == selectedListingId)['type'] == 'GIVE' ? 'give' : 'lend');
                                      _offerHelp(
                                        mode, 
                                        'forever', 
                                        listingId: selectedListingId,
                                        extraDetails: detailsController.text,
                                        handoverLocation: locationController.text,
                                        handoverMethod: methodController.text,
                                      );
                                    } else {
                                      _offerHelp(
                                        selectedType, 
                                        'from ${startDate.toString()} to ${endDate?.toString() ?? "forever"}', 
                                        windowStart: startDate!.toIso8601String(), 
                                        windowEnd: endDate?.toIso8601String(),
                                        extraDetails: detailsController.text,
                                        handoverLocation: locationController.text,
                                        handoverMethod: methodController.text,
                                      );
                                    }
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
    final myOffer = _offers.firstWhere((o) => o['helper_id'] == currentUser && (o['status'] == 'PENDING' || o['status'] == 'ACCEPTED'), orElse: () => <String, dynamic>{});
    final isRequester = req.requesterId == currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.4), shape: BoxShape.circle),
                child: const Icon(CupertinoIcons.back, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isRequester)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.4), shape: BoxShape.circle),
                    child: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                  ),
                  onPressed: _confirmDeleteRequest,
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(32),
              child: Container(
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image or Gradient
                  if (req.imageUrl != null)
                    Image.network(req.imageUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  
                  // Dark overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48), // Bottom padding to stay above the rounded corners
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha:0.4), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 6),
                                    Text('NEED IT NOW', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 10)],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(_getDistanceText(), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Description
                    Text(req.title, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2, letterSpacing: -0.5)),
                    if (req.description != null && req.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(req.description!, style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[700], height: 1.5)),
                    ],
                    const SizedBox(height: 32),
                    
                    // Requester Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha:0.2), blurRadius: 8, offset: const Offset(0, 2))
                            ]
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                            backgroundColor: Colors.white,
                            child: avatar == null ? Text(name[0], style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.bold)) : null,
                          ),
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
                        if (!isRequester)
                          GestureDetector(
                            onTap: () async {
                              if (!hasOffered) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please send an offer first to start chatting!')),
                                );
                                return;
                              }
                              
                              try {
                                final chatRepo = ChatRepository();
                                final convId = await chatRepo.createOrGetConversation(
                                  contextType: 'urgent_offer',
                                  contextId: myOffer['id'],
                                  otherUserId: _request!.requesterId,
                                );
                                
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ConversationPage(
                                        conversationId: convId ?? '',
                                        otherUserName: name,
                                        contextLabel: 'Context: Urgent Request - ${req.title}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: hasOffered ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9), 
                                shape: BoxShape.circle,
                                boxShadow: hasOffered ? [
                                  BoxShadow(color: const Color(0xFF4338CA).withValues(alpha:0.2), blurRadius: 8, offset: const Offset(0, 2))
                                ] : []
                              ),
                              child: Icon(
                                Icons.chat_bubble_rounded, 
                                color: hasOffered ? const Color(0xFF4338CA) : const Color(0xFF64748B), 
                                size: 22
                              ),
                            ),
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
                            
                            String offerType = 'LEND';
                            String listingId = '';
                            try {
                              final data = jsonDecode(offer['available_for_duration'] as String? ?? '{}');
                              offerType = data['type'] as String? ?? 'LEND';
                              listingId = data['listing_id'] as String? ?? '';
                            } catch (_) {
                              // Fallback if not JSON
                            }
                            
                            return GestureDetector(
                              onTap: () => _showOfferDetailsDialog(offer, offerType, listingId, isAccepted, isDeclined),
                              child: Container(
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
                                              Icon(offerType == 'GIVE' ? Icons.favorite : Icons.handshake, size: 14, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(offerType == 'GIVE' ? 'Wants to Give' : 'Wants to Lend', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (req.status == 'ACTIVE' && !isAccepted && !isDeclined)
                                      ElevatedButton(
                                        onPressed: () => _acceptOffer(offer['id'], offer['helper_id'], offerType, listingId),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 24, offset: const Offset(0, -8))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: hasOffered 
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha:0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Offer Sent Successfully', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                        Text('Waiting for neighbour\'s response', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF15803D))),
                      ],
                    ),
                  ),
                  if (myOffer.isNotEmpty && myOffer['status'] == 'PENDING')
                    IconButton(
                      icon: const Icon(CupertinoIcons.trash_circle_fill, color: Colors.redAccent, size: 28),
                      onPressed: () => _confirmDeleteOffer(myOffer['id']),
                      tooltip: 'Cancel Offer',
                    ),
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
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 8,
                      shadowColor: const Color(0xFFEF4444).withValues(alpha:0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text('I Can Help!', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
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
