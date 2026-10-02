import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/data/repositories/chat_repository.dart';
import '../../messages/presentation/conversation_page.dart';
import '../../../core/theme/app_colors.dart';

class OfferDetailPage extends StatefulWidget {
  final String offerId;

  const OfferDetailPage({super.key, required this.offerId});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _offer;
  Map<String, dynamic>? _urgentRequest;
  Map<String, dynamic>? _requesterProfile;
  Map<String, dynamic>? _helperProfile;

  @override
  void initState() {
    super.initState();
    _loadOffer();
  }

  Future<void> _loadOffer() async {
    try {
      final res = await Supabase.instance.client
          .from('urgent_request_offers')
          .select('*, urgent_requests(*, profiles:requester_id(*)), profiles:helper_id(*)')
          .eq('id', widget.offerId)
          .single();
      
      setState(() {
        _offer = res;
        _urgentRequest = res['urgent_requests'];
        _requesterProfile = _urgentRequest?['profiles'];
        _helperProfile = res['profiles'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading offer: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading offer: $e')),
        );
      }
    }
  }

  void _startChat() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;
      
      final isRequester = currentUser.id == _urgentRequest?['requester_id'];
      final otherUserId = isRequester ? _offer!['helper_id'] : _urgentRequest!['requester_id'];
      
      String? otherUserName;
      if (isRequester) {
        otherUserName = _helperProfile != null ? _helperProfile!['display_name'] : null;
      } else {
        otherUserName = _requesterProfile != null ? _requesterProfile!['display_name'] : null;
      }
      
      final chatRepo = ChatRepository();
      final convId = await chatRepo.createOrGetConversation(
        contextType: 'urgent_offer',
        contextId: widget.offerId,
        otherUserId: otherUserId,
      );
      
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              conversationId: convId ?? '',
              otherUserName: otherUserName ?? 'Neighbor',
              contextLabel: 'Context: Urgent Request - ${_urgentRequest?['title']}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting chat: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_offer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offer Details')),
        body: const Center(child: Text('Offer not found.')),
      );
    }

    final isAccepted = _offer!['status'] == 'ACCEPTED';
    final isRejected = _offer!['status'] == 'REJECTED';
    final statusColor = isAccepted
        ? Colors.green
        : isRejected
            ? Colors.red
            : Colors.orange;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAccepted ? Icons.check_circle_rounded : isRejected ? Icons.cancel_rounded : Icons.pending_rounded,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (_offer!['status'] as String).toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Offer for',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _urgentRequest?['title'] ?? 'Urgent Request',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Helper Glass Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              ),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: _helperProfile?['avatar_url'] != null
                                    ? NetworkImage(_helperProfile!['avatar_url'])
                                    : null,
                                child: _helperProfile?['avatar_url'] == null
                                    ? Text(
                                        (_helperProfile?['display_name'] ?? 'N')[0].toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Helper',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _helperProfile?['display_name'] ?? 'Neighbor',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Direct Chat Button
                            GestureDetector(
                              onTap: _startChat,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Offer Message',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message Bubble
                  if (_offer!['message'] != null && _offer!['message'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                          bottomLeft: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Text(
                        _offer!['message'],
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey[800],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.grey[500]),
                          const SizedBox(width: 12),
                          Text(
                            'No additional message provided.',
                            style: GoogleFonts.inter(color: Colors.grey[600], fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_offer!['price_amount'] != null && _offer!['price_amount'] > 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.white],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.payments_rounded, color: Colors.green),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Requested Price',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          Text(
                            '\$${_offer!['price_amount']}',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 1.5)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _startChat,
                          icon: const Icon(Icons.chat_bubble_rounded),
                          label: const Text('Open Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            textStyle: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
