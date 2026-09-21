import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_request.dart';
import '../models/listing.dart';

class RequestRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createRequest(ItemRequest request) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    await _client.from('item_requests').insert({
      'listing_id': request.listingId,
      'requester_id': userId,
      'status': request.status,
      'message': request.message,
      'exchange_listing_id': request.exchangeListingId,
      'duration': request.duration,
      'start_date': request.startDate?.toIso8601String(),
      'end_date': request.endDate?.toIso8601String(),
      'pickup_time': request.pickupTime?.toIso8601String(),
    });
  }

  Future<ItemRequest?> getRequestById(String id) async {
    final response = await _client
        .from('item_requests')
        .select('*, listing:listings!item_requests_listing_id_fkey(*), profiles!item_requests_requester_id_fkey(*)')
        .eq('id', id)
        .maybeSingle();
    
    if (response == null) return null;
    return ItemRequest.fromJson(response);
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _client.rpc(
      'update_req_status',
      params: {'req_id': requestId, 'new_status': status},
    );
  }

  Future<List<Map<String, dynamic>>> getIncomingRequestsWithListings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Get listings owned by this user
    final listings = await _client
        .from('listings')
        .select('id')
        .eq('owner_id', userId);
    if (listings.isEmpty) return [];

    final listingIds = listings.map((l) => l['id'] as String).toList();

    // Get requests for these listings
    final requests = await _client
        .from('item_requests')
        .select(
          '*, listing:listings!item_requests_listing_id_fkey(*), profiles!item_requests_requester_id_fkey(*)',
        )
        .inFilter('listing_id', listingIds)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(requests);
  }

  Future<List<Map<String, dynamic>>> getMyRequestsWithListings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final requests = await _client
        .from('item_requests')
        .select(
          '*, listing:listings!item_requests_listing_id_fkey(*, profiles!listings_owner_id_fkey(*))',
        )
        .eq('requester_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(requests);
  }

  Future<void> generateHandoffCode(String requestId, String code) async {
    await _client.rpc(
      'generate_handoff_code',
      params: {'req_id': requestId, 'pin': code},
    );
  }

  Future<bool> verifyHandoffCode(
    String requestId,
    String code,
    String newStatus,
  ) async {
    final response = await _client.rpc(
      'verify_handoff_code',
      params: {'req_id': requestId, 'pin': code, 'new_status': newStatus},
    );
    return response as bool;
  }

  Future<void> generateReturnCode(String requestId, String code) async {
    await _client.rpc(
      'generate_return_code',
      params: {'req_id': requestId, 'pin': code},
    );
  }

  Future<bool> verifyReturnCode(
    String requestId,
    String code,
  ) async {
    final response = await _client.rpc(
      'verify_return_code',
      params: {'req_id': requestId, 'pin': code},
    );
    return response as bool;
  }
}
