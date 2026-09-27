import re

filepath = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\requests\presentation\urgent_request_detail_page.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _offers state and fetch them
init_state_addition = """
  List<Map<String, dynamic>> _offers = [];

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
"""

content = re.sub(r'  bool _isOffering = false;', r'  bool _isOffering = false;' + init_state_addition, content)

load_request_replacement = """        setState(() {
          _request = UrgentRequest.fromJson(data);
          _requesterProfile = data['profiles'] as Map<String, dynamic>;
          _isLoading = false;
        });
        _loadOffers();"""

content = content.replace("""        setState(() {
          _request = UrgentRequest.fromJson(data);
          _requesterProfile = data['profiles'] as Map<String, dynamic>;
          _isLoading = false;
        });""", load_request_replacement)


# 2. Add accept offer logic
accept_offer_logic = """
  Future<void> _acceptOffer(String offerId, String helperId) async {
    try {
      // 1. Mark this offer as ACCEPTED
      await Supabase.instance.client
          .from('urgent_request_offers')
          .update({'status': 'ACCEPTED'})
          .eq('id', offerId);
          
      // 2. Mark the request as COMPLETED (or ACCEPTED)
      await Supabase.instance.client
          .from('urgent_requests')
          .update({'status': 'COMPLETED'})
          .eq('id', widget.requestId);
          
      // 3. Mark other offers as DECLINED
      await Supabase.instance.client
          .from('urgent_request_offers')
          .update({'status': 'DECLINED'})
          .eq('urgent_request_id', widget.requestId)
          .neq('id', offerId);

      // (In a real production app, we would also generate a transaction here)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted! You can now contact the helper.')),
        );
        _loadRequest(); // reload everything
      }
    } catch (e) {
      debugPrint('Error accepting offer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
"""

content = content.replace('  void _showOfferBottomSheet() {', accept_offer_logic + '\n  void _showOfferBottomSheet() {')

# 3. Build UI for the requester to see offers
offers_ui = """
          if (req.requesterId == Supabase.instance.client.auth.currentUser?.id)
            Positioned(
              top: 420,
              left: 24,
              right: 24,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Responses (${_offers.length})', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_offers.isEmpty)
                    Text('Waiting for neighbours to respond...', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic))
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _offers.length,
                        itemBuilder: (ctx, i) {
                          final offer = _offers[i];
                          final helper = offer['profiles'] as Map<String, dynamic>?;
                          final status = offer['status'] as String;
                          final isAccepted = status == 'ACCEPTED';
                          final isDeclined = status == 'DECLINED' || status == 'REJECTED';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isAccepted ? Colors.green.withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isAccepted ? Colors.green : Colors.grey.withValues(alpha: 0.2)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: helper?['avatar_url'] != null ? NetworkImage(helper!['avatar_url']) : null,
                                  backgroundColor: Colors.grey[200],
                                  child: helper?['avatar_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(helper?['display_name'] ?? 'Neighbour', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('Mode: ${offer['mode']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (req.status == 'ACTIVE' && !isAccepted && !isDeclined)
                                  ElevatedButton(
                                    onPressed: () => _acceptOffer(offer['id'], offer['helper_id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: isAccepted ? Colors.green : (isDeclined ? Colors.red : Colors.grey),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                    )
                                  )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
"""

# Inject offers_ui right before `if (req.status == 'ACTIVE' && req.requesterId != Supabase.instance.client.auth.currentUser?.id)`
content = content.replace("""          if (req.status == 'ACTIVE' && req.requesterId != Supabase.instance.client.auth.currentUser?.id)""", offers_ui + """          if (req.status == 'ACTIVE' && req.requesterId != Supabase.instance.client.auth.currentUser?.id)""")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated urgent_request_detail_page.dart successfully!")
