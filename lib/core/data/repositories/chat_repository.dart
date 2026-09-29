import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/conversation_member.dart';
import '../models/message.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  // 1. Get all conversations for the current user
  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return const Stream.empty();

    // In Supabase we stream conversation_members for the user, 
    // and join the conversations and profiles tables in UI or via RPC.
    // For now, stream members and we can fetch conversation details manually or via view.
    return _client
        .from('conversation_members')
        .stream(primaryKey: ['conversation_id', 'profile_id'])
        .eq('profile_id', currentUserId)
        .order('last_read_at', ascending: false);
  }
  
  Future<List<Map<String, dynamic>>> getConversationsWithDetails() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    try {
      // Fetch conversations where the current user is a member
      final response = await _client.from('conversations')
          .select('''
            *,
            my_membership:conversation_members!inner(profile_id, last_read_at),
            all_members:conversation_members(*, profiles(*)),
            messages(*),
            listing:listing_id(*),
            borrow_request:borrow_request_id(*, listings(*)),
            item_request:item_request_id(*, listings!item_requests_listing_id_fkey(*)),
            urgent_request:urgent_request_id(*),
            urgent_offer:urgent_offer_id(*, urgent_requests(*)),
            loan:loan_id(*)
          ''')
          .eq('my_membership.profile_id', currentUserId);

      // We'll return the raw response, but the UI must parse this structure.

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  // 2. Stream messages for a specific conversation
  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .map((data) => data.map((m) => Message.fromJson(m)).toList())
        .handleError((error) {
          print('Stream error on messages: $error');
        });
  }

  // 3. Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'USER',
    Map<String, dynamic>? metadata,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'message_type': messageType,
        'content': content,
        'metadata': metadata,
      });

      // Update the updated_at on the conversation to bubble it to the top
      await _client.from('conversations').update({
        'updated_at': DateTime.now().toUtc().toIso8601String()
      }).eq('id', conversationId);

    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // 4. Create or get conversation
  Future<String?> createOrGetConversation({
    required String contextType,
    required String contextId,
    required String otherUserId,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    try {
      // A RPC call is usually best here for transaction safety, but we can do it client-side.
      
      final response = await _client.rpc(
        'create_or_get_conversation',
        params: {
          'p_context_type': contextType,
          'p_context_id': contextId,
          'p_other_user_id': otherUserId,
        },
      );
      
      return response as String;

    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // 5. Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _client.from('conversation_members').update({
        'last_read_at': DateTime.now().toUtc().toIso8601String()
      }).eq('conversation_id', conversationId).eq('profile_id', currentUserId);
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }
}
