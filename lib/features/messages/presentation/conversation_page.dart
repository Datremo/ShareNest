import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/avatars.jpg'), // Using avatars as placeholder
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Priya Sharma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                Row(
                  children: const [
                    Icon(Icons.circle, color: AppColors.primary, size: 8),
                    SizedBox(width: 4),
                    Text('Online now', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            )
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildItemContextCard(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildMessageBubble('Hi! Is this still available?', '10:05 AM', false),
                _buildMessageBubble("Yes, it's still available! 😊", '10:09 AM', true),
                _buildMessageBubble("Great! I'm looking to use it this weekend for a small home project.", '10:10 AM', false),
                _buildMessageBubble('Sure! How many days do you need it for?', '10:11 AM', true),
                _buildMessageBubble('Probably 2-3 days. Is that okay?', '10:12 AM', false),
                _buildMessageBubble("Yes, that works. I'll share some quick details about it.", '10:13 AM', true),
                _buildCustomMessageCard(),
                _buildMessageBubble('Perfect! When can I pick it up?', '10:15 AM', false),
                _buildMessageBubble('You can pick it up tomorrow after 6 PM at my society gate.', '10:16 AM', true),
                _buildMessageBubble('Sounds good! I\'ll confirm tomorrow. Thank you! 🙏', '10:17 AM', false),
                _buildMessageBubble('No problem! Looking forward to it. 👍', '10:18 AM', true),
              ],
            ),
          ),
          _buildInputArea(),
          _buildBottomActionStrip(),
        ],
      ),
    );
  }

  Widget _buildItemContextCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/usb_cable.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Camping Tent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text('Sports & Outdoors', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Row(
                      children: const [
                        Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                        Text(' Sainagar, Old Panvel', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  Text('Lending to you', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const Text('Free', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('View Details', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  child: const Text('User Profile', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String time, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primaryLight : AppColors.grey50,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
              border: isMe ? null : Border.all(color: AppColors.grey200),
            ),
            child: Text(text, style: TextStyle(fontSize: 14, color: isMe ? AppColors.primaryDark : AppColors.textPrimary)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              if (isMe) const SizedBox(width: 4),
              if (isMe) const Icon(Icons.done_all, size: 12, color: AppColors.primary),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCustomMessageCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Item details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
                      const SizedBox(height: 8),
                      _checkItem('Comes with tent poles & cover'),
                      _checkItem('In great condition'),
                      _checkItem('Fits 4 people comfortably'),
                      _checkItem('Please handle with care 😊'),
                    ],
                  ),
                ),
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/usb_cable.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('10:13 AM', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              SizedBox(width: 4),
              Icon(Icons.done_all, size: 12, color: AppColors.primary),
            ],
          )
        ],
      ),
    );
  }

  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark))),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(24)),
              child: const Text('Type a message...', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionStrip() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionIcon(Icons.location_on_outlined, 'Share\nLocation'),
          _actionIcon(Icons.calendar_today, 'Request\nExtension'),
          _actionIcon(Icons.handshake_outlined, 'Mark as\nPicked Up'),
          _actionIcon(Icons.check_circle_outline, 'Mark as\nReturned'),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.grey200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
