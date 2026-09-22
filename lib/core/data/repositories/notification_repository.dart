import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  final _client = Supabase.instance.client;

  Future<List<AppNotification>> getNotifications() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('profile_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).map((n) => AppNotification.fromJson(n)).toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('profile_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationStream() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('profile_id', currentUserId)
        .order('created_at', ascending: false)
        .handleError((error) {
          print('Supabase Realtime Stream Error: $error');
          // Swallow the error to prevent the app from crashing on hot restart/disconnects
        });
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final actorId = _client.auth.currentUser?.id;
    try {
      await _client.from('notifications').insert({
        'profile_id': userId,
        'actor_id': actorId,
        'title': title,
        'message': body,
        'type': type,
        'entity_id': relatedId,
        'is_read': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
}
