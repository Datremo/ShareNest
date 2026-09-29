import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/data/repositories/chat_repository.dart';
import '../../../core/data/models/message.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/data/models/listing.dart';
import '../../item/presentation/item_detail_page.dart';
import 'package:image_picker/image_picker.dart';

class ConversationPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String contextLabel;

  const ConversationPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.contextLabel,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _chatRepo = ChatRepository();
  final _textController = TextEditingController();
  final _currentUserId = Supabase.instance.client.auth.currentUser?.id;
  
  Map<String, dynamic>? _convData;
  bool _isLoadingContext = true;

  RealtimeChannel? _presenceChannel;
  bool _isOtherOnline = false;
  bool _isOtherTyping = false;
  DateTime? _otherLastSeen;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _chatRepo.markAsRead(widget.conversationId);
    _loadConversationContext();
    _initPresence();
  }

  void _initPresence() {
    _presenceChannel = Supabase.instance.client.channel('presence:conv_${widget.conversationId}');
    
    _presenceChannel!
      .onPresenceSync((payload) {
        final state = _presenceChannel!.presenceState();
        bool isOnline = false;
        
        for (final entry in state) {
          final presences = entry.presences;
          for (final p in presences) {
            if (p.payload['user_id'] != _currentUserId) {
               isOnline = true;
            }
          }
        }
        
        if (mounted) {
           setState(() {
              _isOtherOnline = isOnline;
              if (isOnline) _otherLastSeen = DateTime.now();
           });
        }
      })
      .onBroadcast(event: 'typing', callback: (payload) {
        if (payload['user_id'] != _currentUserId) {
           if (mounted) setState(() => _isOtherTyping = true);
           _typingTimer?.cancel();
           _typingTimer = Timer(const Duration(seconds: 3), () {
             if (mounted) setState(() => _isOtherTyping = false);
           });
        }
      })
      .subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
           await _presenceChannel!.track({'user_id': _currentUserId});
        }
      });
  }

  Future<void> _loadConversationContext() async {
    // Fetch details about this specific conversation to populate the header card
    try {
      final res = await Supabase.instance.client.from('conversations')
        .select('''
          *,
          listing:listing_id(*),
          borrow_request:borrow_request_id(*, listings(*)),
          item_request:item_request_id(*, listings!item_requests_listing_id_fkey(*)),
          urgent_request:urgent_request_id(*),
          urgent_offer:urgent_offer_id(*, urgent_requests(*)),
          loan:loan_id(*),
          all_members:conversation_members(*, profiles(*))
        ''')
        .eq('id', widget.conversationId)
        .maybeSingle();
        
      if (mounted) {
        setState(() {
          _convData = res;
          _isLoadingContext = false;
        });
      }
    } catch (e) {
      print('Failed to load context: $e');
      if (mounted) setState(() => _isLoadingContext = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _presenceChannel?.unsubscribe();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTyping() {
    if (_textController.text.isNotEmpty) {
      _presenceChannel?.sendBroadcastMessage(
        event: 'typing',
        payload: {'user_id': _currentUserId},
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await _chatRepo.sendMessage(
      conversationId: widget.conversationId,
      content: text,
    );
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image != null) {
      try {
        final bytes = await image.readAsBytes();
        final ext = image.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = '$_currentUserId/$fileName';
        
        await Supabase.instance.client.storage.from('offer_photos').uploadBinary(path, bytes);
        final url = Supabase.instance.client.storage.from('offer_photos').getPublicUrl(path);
        
        await _chatRepo.sendMessage(
          conversationId: widget.conversationId,
          content: 'Sent an image',
          messageType: 'IMAGE',
          metadata: {'image_url': url},
        );
      } catch(e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
        }
      }
    }
  }

  Future<void> _cancelTransaction() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transaction'),
        content: const Text('Are you sure you want to cancel this transaction? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Cancel Transaction', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
    
    if (confirm != true || _convData == null) return;
    
    try {
       if (_convData!['item_request'] != null) {
          await Supabase.instance.client.from('item_requests').update({'status': 'CANCELLED'}).eq('id', _convData!['item_request']['id']);
       } else if (_convData!['borrow_request'] != null) {
          await Supabase.instance.client.from('borrow_requests').update({'status': 'CANCELLED'}).eq('id', _convData!['borrow_request']['id']);
       } else if (_convData!['urgent_request'] != null) {
          await Supabase.instance.client.from('urgent_requests').update({'status': 'CANCELLED'}).eq('id', _convData!['urgent_request']['id']);
       }
       
       await _chatRepo.sendMessage(
         conversationId: widget.conversationId,
         content: 'Transaction cancelled.',
         messageType: 'SYSTEM'
       );
       
       await Supabase.instance.client.from('conversations').update({'status': 'ARCHIVED'}).eq('id', widget.conversationId);
       
       if (mounted) {
         setState(() {
            _convData!['status'] = 'ARCHIVED';
         });
       }
       
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool _isConversationClosed() {
    if (_convData == null) return false;
    if (_convData!['status'] == 'ARCHIVED') return true;
    
    // Check loan status
    final loan = _convData!['loan'];
    if (loan != null && (loan['status'] == 'completed' || loan['status'] == 'cancelled')) return true;
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _isConversationClosed();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Row(
                    children: [
                      if (_isOtherTyping) ...[
                        const Icon(Icons.edit, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        const Text('typing...', style: TextStyle(fontSize: 11, color: AppColors.primary, fontStyle: FontStyle.italic)),
                      ] else if (_isOtherOnline) ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text('Online', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)),
                      ] else ...[
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(
                           _otherLastSeen != null ? 'Last seen ${timeago.format(_otherLastSeen!)}' : 'Offline', 
                           style: const TextStyle(fontSize: 11, color: Colors.grey)
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) async {
              if (value == 'report') {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User reported.')));
              } else if (value == 'block') {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked.')));
              } else if (value == 'cancel') {
                 await _cancelTransaction();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'report', child: Text('Report')),
              const PopupMenuItem(value: 'block', child: Text('Block User')),
              const PopupMenuItem(value: 'cancel', child: Text('Cancel Transaction', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoadingContext)
            const LinearProgressIndicator(color: Color(0xFF1D5A50))
          else if (_convData != null)
            _buildContextHeaderCard(),
            
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatRepo.getMessagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator(color: Color(0xFF1D5A50)));
                }
                
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet.\nSay hello!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          
          if (isClosed)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text('This conversation is closed.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            )
          else
            _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildContextHeaderCard() {
    // Extract info logically from _convData
    String title = 'Item';
    String location = 'Nearby';
    String conditionOrDates = '';
    String badgeText = widget.contextLabel.toUpperCase();
    Color badgeColor = const Color(0xFF1D5A50);
    
    String photoUrl = '';
    String otherAvatarUrl = '';
    Map<String, dynamic>? itemData;
    
    if (_convData!['all_members'] != null) {
       final allMembers = _convData!['all_members'] as List<dynamic>;
       final otherMembers = allMembers.where((m) => m['profile_id'] != _currentUserId).toList();
       if (otherMembers.isNotEmpty && otherMembers.first['profiles'] != null) {
          otherAvatarUrl = otherMembers.first['profiles']['avatar_url'] ?? '';
       }
    }
    
    if (_convData!['listing'] != null) {
       title = _convData!['listing']['title'] ?? 'Listing';
       conditionOrDates = _convData!['listing']['condition'] ?? 'Good condition';
       location = _convData!['listing']['location_text'] ?? 'Nearby';
       badgeText = 'LEND - ITEM';
       final photos = _convData!['listing']['photo_urls'] as List<dynamic>?;
       if (photos != null && photos.isNotEmpty) photoUrl = photos.first.toString();
       itemData = _convData!['listing'];
    } else if (_convData!['item_request'] != null || _convData!['borrow_request'] != null) {
       final req = _convData!['item_request'] ?? _convData!['borrow_request'];
       title = req['listings']?['title'] ?? 'Requested Item';
       location = req['listings']?['location_text'] ?? 'Nearby';
       badgeText = 'REQUEST - PENDING';
       badgeColor = Colors.orange.shade700;
       
       final photos = req['listings']?['photo_urls'] as List<dynamic>?;
       if (photos != null && photos.isNotEmpty) photoUrl = photos.first.toString();
       itemData = req['listings'];
       
       final startDate = req['start_date'];
       if (startDate != null) {
          conditionOrDates = 'Requested: ${DateTime.parse(startDate).month}/${DateTime.parse(startDate).day}';
       }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      image: photoUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: photoUrl.isEmpty ? const Icon(Icons.handyman, color: Colors.grey) : null,
                  ),
                  if (otherAvatarUrl.isNotEmpty)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(otherAvatarUrl),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(conditionOrDates, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          InkWell(
            onTap: () {
               if (itemData != null) {
                  final listing = Listing.fromJson(itemData!);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemDetailPage(listing: listing)));
               }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('View Details', style: TextStyle(color: Color(0xFF1D5A50), fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: Color(0xFF1D5A50)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    if (message.messageType == 'SYSTEM') {
      return _buildSystemEventCard(message);
    }

    final isMe = message.senderId == _currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFDDF5ED) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.messageType == 'IMAGE' && message.metadata?['image_url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.metadata!['image_url'],
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty && message.content != 'Sent an image')
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? const Color(0xFF0F3A32) : Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt?.toLocal()),
                        style: TextStyle(fontSize: 10, color: isMe ? const Color(0xFF1D5A50).withOpacity(0.7) : Colors.grey),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 12, color: Color(0xFF1D5A50)),
                      ]
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemEventCard(Message message) {
    // Basic heuristics for structured card UI based on content
    IconData icon = Icons.info_outline;
    Color iconColor = const Color(0xFF1D5A50);
    String title = 'System Update';
    
    final contentLower = message.content.toLowerCase();
    bool isSimplePill = contentLower.contains('accepted') || 
                        contentLower.contains('started') || 
                        contentLower.contains('handed over') || 
                        contentLower.contains('verified') || 
                        contentLower.contains('completed') || 
                        contentLower.contains('returned') ||
                        contentLower.contains('generated') ||
                        contentLower.contains('closed') ||
                        contentLower.contains('cancelled') ||
                        contentLower.contains('sent');

    if (isSimplePill) {
       IconData icon = Icons.check_circle;
       Color iconBg = const Color(0xFF1D5A50);
       
       if (contentLower.contains('started') || contentLower.contains('generated')) {
          icon = Icons.security;
       } else if (contentLower.contains('accepted')) {
          icon = Icons.check;
          iconBg = const Color(0xFF34A853);
       } else if (contentLower.contains('handed over') || contentLower.contains('verified') || contentLower.contains('returned')) {
          icon = Icons.handshake;
       } else if (contentLower.contains('sent')) {
          icon = Icons.send;
       } else if (contentLower.contains('closed') || contentLower.contains('completed')) {
          icon = Icons.done_all;
       } else if (contentLower.contains('cancelled')) {
          icon = Icons.cancel;
          iconBg = Colors.red;
       }
       
       return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                 child: Icon(icon, color: Colors.white, size: 16),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       message.content,
                       style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1F2937)),
                     ),
                     const SizedBox(height: 2),
                     Text(
                       message.createdAt != null ? timeago.format(message.createdAt!) : '',
                       style: const TextStyle(fontSize: 11, color: Colors.grey),
                     )
                   ],
                 )
               )
            ],
          ),
       );
    }

    if (contentLower.contains('borrow request')) {
       icon = Icons.description;
       title = 'Borrow request update';
    } 

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            message.content,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text('View Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            InkWell(
              onTap: _pickAndSendImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.add, color: Colors.grey, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Message ${widget.otherUserName}...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFF1D5A50), shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
