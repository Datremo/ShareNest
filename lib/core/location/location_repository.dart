import 'package:supabase_flutter/supabase_flutter.dart';

class LocationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stubs for future implementation

  Future<void> saveHomeLocation(double lat, double lng) async {
    // Phase 3 implementation
  }

  Future<void> savePickupLocation(String postId, double lat, double lng) async {
    // Phase 7 implementation
  }

  Future<void> saveHandoverLocation(String transactionId, double lat, double lng) async {
    // Phase 8 implementation
  }

  Future<List<Map<String, dynamic>>> getNearbyUrgentRequests(double lat, double lng, int radiusMeters) async {
    // Phase 5 implementation (RPC call to nearby_open_urgent_requests)
    return [];
  }

  Future<List<Map<String, dynamic>>> getPostsInBounds(double minLng, double minLat, double maxLng, double maxLat) async {
    // Phase 4 implementation (RPC call to posts_in_map_bounds)
    return [];
  }

  Future<List<Map<String, dynamic>>> getNearbyPosts(double lat, double lng) async {
    // Phase 4 implementation (RPC call to nearby_posts)
    return [];
  }
}
