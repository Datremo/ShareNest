import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing.dart';

class ListingRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadListingImage(Uint8List bytes, String ext) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '${user.id}/$fileName';
    await _client.storage.from('listing_images').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$ext'),
    );
    return _client.storage.from('listing_images').getPublicUrl(path);
  }

  Future<void> createListing(Listing listing) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Insert into PostgreSQL
    final payload = listing.toJson();
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');
    
    if (listing.photoUrls.isNotEmpty) {
      payload['photo_urls'] = listing.photoUrls;
    }

    await _client.from('listings').insert(payload);
  }

  Future<void> updateListing(Listing listing) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final payload = listing.toJson();
    payload.remove('id');
    payload.remove('created_at');
    payload.remove('updated_at');

    if (listing.photoUrls.isNotEmpty) {
      payload['photo_urls'] = listing.photoUrls;
    }

    await _client.from('listings').update(payload).eq('id', listing.id);
  }

  // Future for Home/Explore Feed (Fallback from Stream to avoid Realtime exceptions)
  Future<List<Listing>> getActiveListings() async {
    final response = await _client
        .from('listings')
        .select()
        .eq('status', 'ACTIVE')
        .order('created_at', ascending: false);
    return (response as List).map((e) => Listing.fromJson(e)).toList();
  }

  Future<List<Listing>> getUserListings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    
    final response = await _client
        .from('listings')
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Listing.fromJson(e)).toList();
  }

  /// Fetch active listings filtered by mode (LEND, GIVE, EXCHANGE)
  Future<List<Listing>> getListingsByMode(String mode) async {
    final response = await _client
        .from('listings')
        .select()
        .eq('status', 'ACTIVE')
        .eq('mode', mode)
        .order('created_at', ascending: false);
    return (response as List).map((e) => Listing.fromJson(e)).toList();
  }

  /// Delete a listing by ID
  Future<void> deleteListing(String id) async {
    await _client.from('listings').delete().eq('id', id);
  }
}
