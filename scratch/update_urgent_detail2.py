import re

filepath = r'C:\Users\Shubham\StudioProjects\neighbor_share\lib\features\requests\presentation\urgent_request_detail_page.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the existing _acceptOffer method
new_accept_offer = """
  Future<void> _acceptOffer(String offerId, String helperId, String mode, String? offeredListingId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Determine the listing ID to use
      String listingIdToUse;
      if (offeredListingId != null) {
        listingIdToUse = offeredListingId;
      } else {
        // Create a hidden/private listing for this transaction
        final newListing = await supabase.from('listings').insert({
          'owner_id': helperId,
          'title': _request!.title,
          'mode': mode.toUpperCase(),
          'category_id': 'urgent_category', // dummy category
          'description': 'Urgent fulfillment for: ${_request!.title}',
          'status': 'ACTIVE',
          'is_urgent_fulfillment': true,
        }).select('id').single();
        listingIdToUse = newListing['id'] as String;
      }

      // 2. Create the ItemRequest (the transaction)
      await supabase.from('item_requests').insert({
        'listing_id': listingIdToUse,
        'requester_id': _request!.requesterId,
        'status': 'ACCEPTED',
        'is_urgent': true,
        'message': 'Urgent Request Accepted',
        'duration': _request!.duration,
      });

      // 3. Update the offer status
      await supabase
          .from('urgent_request_offers')
          .update({'status': 'ACCEPTED'})
          .eq('id', offerId);
          
      // 4. Update the urgent request status
      await supabase
          .from('urgent_requests')
          .update({'status': 'COMPLETED'})
          .eq('id', widget.requestId);
          
      // 5. Decline other offers
      await supabase
          .from('urgent_request_offers')
          .update({'status': 'DECLINED'})
          .eq('urgent_request_id', widget.requestId)
          .neq('id', offerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted! Check your activity/dashboard for the transaction.')),
        );
        context.pop(); // Close the page, go back to activity
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

# Find the old _acceptOffer and replace it
content = re.sub(r'  Future<void> _acceptOffer\(String offerId, String helperId\) async \{.*?(?=  void _showOfferBottomSheet\(\) \{)', new_accept_offer, content, flags=re.DOTALL)

# Also update the call site: onPressed: () => _acceptOffer(offer['id'], offer['helper_id']),
call_site_replacement = "onPressed: () => _acceptOffer(offer['id'], offer['helper_id'], offer['mode'], offer['offered_listing_id']),"
content = content.replace("onPressed: () => _acceptOffer(offer['id'], offer['helper_id']),", call_site_replacement)

# Task 1: Hide "I Can Help" if already offered
# Right before "if (req.status == 'ACTIVE' && req.requesterId != Supabase.instance.client.auth.currentUser?.id)", we need to check if currentUser has offered.
hide_button_injection = """
          final currentUser = Supabase.instance.client.auth.currentUser?.id;
          final hasOffered = _offers.any((o) => o['helper_id'] == currentUser && (o['status'] == 'PENDING' || o['status'] == 'ACCEPTED'));
          
          if (req.status == 'ACTIVE' && req.requesterId != currentUser && !hasOffered)
            Positioned(
"""
content = content.replace("if (req.status == 'ACTIVE' && req.requesterId != Supabase.instance.client.auth.currentUser?.id)\n            Positioned(", hide_button_injection)

# Also add a "Waiting for requester" text if they HAVE offered
waiting_injection = """
          if (req.status == 'ACTIVE' && req.requesterId != currentUser && hasOffered)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Text('Offer Sent. Waiting for response...', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
"""
content = content.replace("if (req.status == 'ACTIVE' && req.requesterId != currentUser && !hasOffered)\n            Positioned(", waiting_injection + "\n          if (req.status == 'ACTIVE' && req.requesterId != currentUser && !hasOffered)\n            Positioned(")


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("urgent_request_detail_page.dart updated successfully!")
