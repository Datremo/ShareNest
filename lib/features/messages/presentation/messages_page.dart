import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/chat_repository.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'conversation_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _chatRepo = ChatRepository();
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Needs Action', 'Active', 'Archived'];
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    final lowerQuery = _searchQuery.toLowerCase();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return _conversations.where((conv) {
      // Extract other user name
      final allMembers = conv['all_members'] as List<dynamic>? ?? [];
      final otherMembers = allMembers.where((m) => m['profile_id'] != currentUserId).toList();
      String otherUser = '';
      if (otherMembers.isNotEmpty && otherMembers.first['profiles'] != null) {
        otherUser = (otherMembers.first['profiles']['display_name'] as String?)?.toLowerCase() ?? '';
      }

      // Extract item title
      String title = '';
      if (conv['listing'] != null) {
        title = (conv['listing']['title'] as String?)?.toLowerCase() ?? '';
      } else if (conv['item_request'] != null) {
        title = (conv['item_request']['listings']?['title'] as String?)?.toLowerCase() ?? '';
      } else if (conv['borrow_request'] != null) {
        title = (conv['borrow_request']['listings']?['title'] as String?)?.toLowerCase() ?? '';
      }

      // Extract last message
      String lastMsg = '';
      final messages = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
      if (messages.isNotEmpty) {
        messages.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
        lastMsg = (messages.first['content'] as String?)?.toLowerCase() ?? '';
      }

      return title.contains(lowerQuery) || otherUser.contains(lowerQuery) || lastMsg.contains(lowerQuery);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadConversations();
    
    Supabase.instance.client.channel('messages_page_messages').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        _loadConversations();
      },
    ).subscribe();

    Supabase.instance.client.channel('messages_page_conversations').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      callback: (payload) {
        _loadConversations();
      },
    ).subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.channel('messages_page_messages').unsubscribe();
    Supabase.instance.client.channel('messages_page_conversations').unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final convs = await _chatRepo.getConversationsWithDetails();
    if (mounted) {
      setState(() {
        _conversations = convs;
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';
    return timeago.format(date, locale: 'en_short');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Very light green/grey background
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSearchBar()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildTabs()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          
          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1)
            ..._buildSection(
              title: 'Needs Your Attention',
              badgeCount: _getNeedsActionCount(),
              items: _buildNeedsActionItems(),
              titleColor: Colors.red,
            ),
          
          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2)
            ..._buildSection(
              title: 'Active Conversations',
              items: _buildActiveItems(),
            ),

          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3)
            ..._buildSection(
              title: 'Archived',
              items: _buildArchivedItems(),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 150.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF14453D),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F3A32), Color(0xFF1D5A50)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text('Chat', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Coordinate, help and share with neighbours.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ]
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(CupertinoIcons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    int needsActionCount = _getNeedsActionCount();
    
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1D5A50) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(
                    _filters[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (index == 1 && needsActionCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        needsActionCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getNeedsActionCount() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return _filteredConversations.where((conv) {
      final membership = (conv['my_membership'] as List<dynamic>?)?.firstOrNull;
      // We check if it requires attention (unread messages or specific request status).
      // For now, if unread count > 0, it needs action.
      if (membership == null || conv['status'] == 'ARCHIVED') return false;
      
      final messages = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
      if (messages.isEmpty) return false;
      messages.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      
      final lastReadAtStr = membership['last_read_at'] as String?;
      final msgCreatedAtStr = messages.first['created_at'] as String?;
      final msgSenderId = messages.first['sender_id'] as String?;
      
      if (msgCreatedAtStr != null && msgSenderId != currentUserId) {
         final msgTime = DateTime.parse(msgCreatedAtStr);
         if (lastReadAtStr == null) return true;
         final readTime = DateTime.parse(lastReadAtStr);
         if (msgTime.isAfter(readTime)) return true;
      }
      return false;
    }).length;
  }

  List<Widget> _buildSection({required String title, required List<Widget> items, int badgeCount = 0, Color titleColor = Colors.black87}) {
    if (items.isEmpty) return [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => items[index],
          childCount: items.length,
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  List<Widget> _buildNeedsActionItems() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final needsAction = _filteredConversations.where((conv) {
      final membership = (conv['my_membership'] as List<dynamic>?)?.firstOrNull;
      if (membership == null || conv['status'] == 'ARCHIVED') return false;
      
      final messages = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
      if (messages.isEmpty) return false;
      messages.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      
      final lastReadAtStr = membership['last_read_at'] as String?;
      final msgCreatedAtStr = messages.first['created_at'] as String?;
      final msgSenderId = messages.first['sender_id'] as String?;
      
      if (msgCreatedAtStr != null && msgSenderId != currentUserId) {
         final msgTime = DateTime.parse(msgCreatedAtStr);
         if (lastReadAtStr == null) return true;
         final readTime = DateTime.parse(lastReadAtStr);
         if (msgTime.isAfter(readTime)) return true;
      }
      return false;
    }).toList();

    return needsAction.map((conv) {
      final allMembers = conv['all_members'] as List<dynamic>? ?? [];
      final otherMembers = allMembers.where((m) => m['profile_id'] != currentUserId).toList();
      String otherName = 'Unknown';
      String otherAvatar = '';
      if (otherMembers.isNotEmpty && otherMembers.first['profiles'] != null) {
        otherName = otherMembers.first['profiles']['display_name'] ?? 'Unknown';
        otherAvatar = otherMembers.first['profiles']['photo_url'] ?? '';
      }

      String itemTitle = 'Item';
      String photoUrl = '';
      if (conv['listing'] != null) {
        itemTitle = conv['listing']['title'] ?? 'Listing';
        final photos = conv['listing']['photo_urls'] as List<dynamic>?;
        if (photos != null && photos.isNotEmpty) photoUrl = photos.first.toString();
      } else if (conv['item_request'] != null) {
        itemTitle = conv['item_request']['listings']?['title'] ?? 'Item Request';
        final photos = conv['item_request']['listings']?['photo_urls'] as List<dynamic>?;
        if (photos != null && photos.isNotEmpty) photoUrl = photos.first.toString();
      } else if (conv['urgent_offer'] != null) {
        String offerTypeStr = 'OFFER';
        final dur = conv['urgent_offer']['available_for_duration'];
        if (dur != null) {
          try {
            final parsed = dur is String ? jsonDecode(dur) : dur;
            offerTypeStr = parsed['type']?.toString().toUpperCase() ?? 'OFFER';
          } catch (_) {}
        }
        itemTitle = 'Urgent $offerTypeStr: ' + (conv['urgent_offer']['urgent_requests']?['title'] ?? 'Request');
        // Urgent offers don't have direct photos in the same way, but we could add if needed
      } else if (conv['borrow_request'] != null) {
        itemTitle = conv['borrow_request']['listings']?['title'] ?? 'Borrow Request';
        final photos = conv['borrow_request']['listings']?['photo_urls'] as List<dynamic>?;
        if (photos != null && photos.isNotEmpty) photoUrl = photos.first.toString();
      }

      String timeAgo = 'Just now';
      String actionStatus = 'Needs attention';
      String buttonText = 'View chat ->';
      
      final req = conv['item_request'] ?? conv['borrow_request'];
      final String? reqStatus = req?['status']?.toString().toUpperCase();
      
      final messages = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
      if (messages.isNotEmpty) {
        messages.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
        timeAgo = _formatTime(messages.first['created_at']);
        
        final lastMsg = messages.first;
        if (lastMsg['message_type'] == 'SYSTEM' && reqStatus != null) {
            // State-driven from DB status
            final isOwner = conv['listing'] != null && conv['listing']['owner_id'] == currentUserId;
            
            if (reqStatus == 'PENDING') {
               actionStatus = isOwner ? 'New borrowing request' : 'Request pending';
               buttonText = isOwner ? 'Review request ->' : 'View status ->';
            } else if (reqStatus == 'ACCEPTED') {
               actionStatus = 'Request accepted';
               buttonText = 'Coordinate handover ->';
            } else if (reqStatus == 'ACTIVE') {
               actionStatus = 'Item handed over';
               buttonText = 'View details ->';
            } else if (reqStatus == 'COMPLETED') {
               actionStatus = 'Transaction completed';
               buttonText = 'View receipt ->';
            } else {
               actionStatus = 'Status update';
               buttonText = 'View chat ->';
            }
        } else {
            // Normal chat message
            actionStatus = 'New unread message';
            buttonText = 'Reply ->';
        }
      }
      
      return _buildActionableCard(
        name: otherName,
        itemTitle: itemTitle,
        actionStatus: actionStatus,
        buttonText: buttonText,
        timeAgo: timeAgo,
        imageUrl: photoUrl,
        userAvatarUrl: otherAvatar,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversationId: conv['id'],
                otherUserName: otherName,
                contextLabel: 'Context',
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildActionableCard({
    required String name,
    required String itemTitle,
    required String actionStatus,
    required String buttonText,
    required String timeAgo,
    required String imageUrl,
    String? userAvatarUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Avatar overlay
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade200,
                      image: imageUrl.isNotEmpty 
                        ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                        : null,
                    ),
                    child: imageUrl.isEmpty ? const Icon(Icons.handyman, color: Colors.grey) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.primary,
                        backgroundImage: userAvatarUrl != null && userAvatarUrl.isNotEmpty ? NetworkImage(userAvatarUrl) : null,
                        child: userAvatarUrl == null || userAvatarUrl.isEmpty
                          ? Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 10, color: Colors.white))
                          : null,
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(timeAgo, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text(itemTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(actionStatus, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(buttonText, style: const TextStyle(color: Color(0xFF1D5A50), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveItems() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final active = _filteredConversations.where((conv) {
      final membership = (conv['my_membership'] as List<dynamic>?)?.firstOrNull;
      return membership != null && conv['status'] != 'ARCHIVED';
    }).toList();
    
    active.sort((a, b) => (b['updated_at'] ?? '').compareTo(a['updated_at'] ?? ''));

    return active.map((conv) {
      final allMembers = conv['all_members'] as List<dynamic>? ?? [];
      final messages = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
      messages.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

      final otherMembers = allMembers.where((m) => m['profile_id'] != currentUserId).toList();

      String otherName = 'Unknown';
      String otherAvatar = '';
      if (otherMembers.isNotEmpty && otherMembers.first['profiles'] != null) {
        otherName = otherMembers.first['profiles']['display_name'] ?? 'Unknown';
        otherAvatar = otherMembers.first['profiles']['photo_url'] ?? '';
      }

      String lastMsg = 'Started conversation';
      String timeAgo = '';
      if (messages.isNotEmpty) {
        lastMsg = messages.first['content'] ?? '';
        timeAgo = _formatTime(messages.first['created_at']);
      }

      final myMembership = (conv['my_membership'] as List<dynamic>?)?.firstOrNull;
      final lastReadAtStr = myMembership?['last_read_at'] as String?;
      final msgCreatedAtStr = messages.isNotEmpty ? messages.first['created_at'] as String? : null;
      final msgSenderId = messages.isNotEmpty ? messages.first['sender_id'] as String? : null;
      
      int unread = 0;
      if (msgCreatedAtStr != null && msgSenderId != currentUserId) {
         final msgTime = DateTime.parse(msgCreatedAtStr);
         if (lastReadAtStr == null) {
            unread = 1;
         } else {
            final readTime = DateTime.parse(lastReadAtStr);
            if (msgTime.isAfter(readTime)) unread = 1;
         }
      }
      
      String itemTitle = 'Chat';
      if (conv['listing'] != null) {
        itemTitle = conv['listing']['title'] ?? 'Listing';
      } else if (conv['item_request'] != null) {
        itemTitle = conv['item_request']['listings']?['title'] ?? 'Item Request';
      } else if (conv['borrow_request'] != null) {
        itemTitle = conv['borrow_request']['listings']?['title'] ?? 'Borrow Request';
      } else if (conv['urgent_offer'] != null) {
        String offerTypeStr = 'OFFER';
        final dur = conv['urgent_offer']['available_for_duration'];
        if (dur != null) {
          try {
            final parsed = dur is String ? jsonDecode(dur) : dur;
            offerTypeStr = parsed['type']?.toString().toUpperCase() ?? 'OFFER';
          } catch (_) {}
        }
        itemTitle = 'Urgent $offerTypeStr: ' + (conv['urgent_offer']['urgent_requests']?['title'] ?? 'Request');
      }

      return _buildConversationRow(
        convId: conv['id'],
        name: otherName,
        itemTitle: itemTitle,
        lastMessage: lastMsg,
        timeAgo: timeAgo,
        unreadCount: unread,
        statusBadge: null, // Logic to determine if "Offer sent" badge should show
        avatarUrl: otherAvatar,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConversationPage(
                conversationId: conv['id'],
                otherUserName: otherName,
                contextLabel: 'Context',
              ),
            ),
          );
        },
      );
    }).toList();
  }
  
  List<Widget> _buildArchivedItems() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final archived = _filteredConversations.where((conv) {
      final membership = (conv['my_membership'] as List<dynamic>?)?.firstOrNull;
      return membership != null && conv['status'] == 'ARCHIVED';
    }).toList();
    
    archived.sort((a, b) => (b['updated_at'] ?? '').compareTo(a['updated_at'] ?? ''));

    return archived.map((conv) {
      final allMembers = conv['all_members'] as List<dynamic>? ?? [];
      final messages = List<Map<String, dynamic>>.from(conv['messages'] ?? []);
      messages.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

      final otherMembers = allMembers.where((m) => m['profile_id'] != currentUserId).toList();

      String otherName = 'Unknown';
      String otherAvatar = '';
      if (otherMembers.isNotEmpty && otherMembers.first['profiles'] != null) {
        otherName = otherMembers.first['profiles']['display_name'] ?? 'Unknown';
        otherAvatar = otherMembers.first['profiles']['photo_url'] ?? '';
      }

      String lastMsg = 'Started conversation';
      String timeAgo = '';
      if (messages.isNotEmpty) {
        lastMsg = messages.first['content'] ?? '';
        timeAgo = _formatTime(messages.first['created_at']);
      }
      
      String itemTitle = 'Archived Chat';
      if (conv['listing'] != null) {
        itemTitle = conv['listing']['title'] ?? 'Listing';
      } else if (conv['item_request'] != null) {
        itemTitle = conv['item_request']['listings']?['title'] ?? 'Item Request';
      } else if (conv['borrow_request'] != null) {
        itemTitle = conv['borrow_request']['listings']?['title'] ?? 'Borrow Request';
      } else if (conv['urgent_offer'] != null) {
        String offerTypeStr = 'OFFER';
        final dur = conv['urgent_offer']['available_for_duration'];
        if (dur != null) {
          try {
            final parsed = dur is String ? jsonDecode(dur) : dur;
            offerTypeStr = parsed['type']?.toString().toUpperCase() ?? 'OFFER';
          } catch (_) {}
        }
        itemTitle = 'Urgent $offerTypeStr: ' + (conv['urgent_offer']['urgent_requests']?['title'] ?? 'Request');
      }

      return Opacity(
        opacity: 0.6,
        child: _buildConversationRow(
          convId: conv['id'],
          name: otherName,
          itemTitle: itemTitle,
          lastMessage: lastMsg,
          timeAgo: timeAgo,
          unreadCount: 0, // Assume no badges for archived items
          statusBadge: 'Closed', 
          avatarUrl: otherAvatar,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ConversationPage(
                  conversationId: conv['id'],
                  otherUserName: otherName,
                  contextLabel: 'Context',
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildConversationRow({
    required String convId,
    required String name,
    required String itemTitle,
    required String lastMessage,
    required String timeAgo,
    int unreadCount = 0,
    String? statusBadge,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    final hasUnread = unreadCount > 0;
    
    return InkWell(
      onTap: onTap,
      onLongPress: () async {
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete Conversation"),
              content: const Text("Are you sure you want to delete this conversation?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("CANCEL"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          try {
            await _chatRepo.deleteConversation(convId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation deleted')));
              _loadConversations();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting conversation: $e')));
              _loadConversations();
            }
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(fontSize: 15, fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600)),
                      Text(timeAgo, style: TextStyle(fontSize: 12, color: hasUnread ? Colors.red : Colors.grey)),
                    ],
                  ),
                  Text(itemTitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  if (statusBadge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer, size: 12, color: Colors.orange.shade800),
                          const SizedBox(width: 4),
                          Text(statusBadge, style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    lastMessage, 
                    style: TextStyle(
                      fontSize: 13, 
                      color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
