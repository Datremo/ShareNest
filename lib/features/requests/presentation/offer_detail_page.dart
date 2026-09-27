import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF4B4B)),
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
        ? const Color(0xFF34C759)
        : isRejected
            ? Colors.red
            : Colors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                (_offer!['status'] as String).toUpperCase(),
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Offer for: ${_urgentRequest?['title'] ?? 'Urgent Request'}',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Helper info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _helperProfile?['avatar_url'] != null
                      ? NetworkImage(_helperProfile!['avatar_url'])
                      : null,
                  child: _helperProfile?['avatar_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _helperProfile?['full_name'] ?? 'Neighbor',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Offered Help',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            Text(
              'Offer Details',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_offer!['message'] != null && _offer!['message'].toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _offer!['message'],
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
            
            if (_offer!['price_amount'] != null && _offer!['price_amount'] > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Price: \$${_offer!['price_amount']}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 32),
            
            if (_offer!['status'] == 'PENDING')
              Text(
                'Waiting for the requester to accept this offer.',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
