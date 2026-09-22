import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 8),
                  _buildMessageList(),
                  const SizedBox(height: 120), // padding for sticky bottom card
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildStickyInfoCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Text('ShareNest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Messages', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Chat, coordinate and build a kinder neighbourhood.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['All', 'Active', 'Borrowing', 'Lending', 'Archived'];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAll ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isAll ? AppColors.primary : AppColors.grey200),
            ),
            child: Text(
              tabs[index],
              style: TextStyle(
                color: isAll ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isAll ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          );
        },
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
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Search conversations...', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.grey200)),
              ),
              child: const Icon(Icons.tune, color: AppColors.textPrimary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Column(
      children: [
        _messageItem('Priya Sharma', '10:24 AM', 'Camping Tent', 'Yes, I can pick it up tomorrow!', '2', true),
        _messageItem('Rohit Mehta', '9:18 AM', 'Cordless Drill', 'Is it still available?', '1', true),
        _messageItem('Sneha Patil', 'Yesterday', 'Set of Fiction Books', 'Thank you so much! 📚', null, false),
        _messageItem('Amit Kulkarni', 'Yesterday', 'Ladder', 'Can you extend by 2 days?', null, false),
        _messageItem('Neha Gupta', 'Mon', 'Yoga Mat', "It's in great condition 👍", null, false),
        _messageItem('Vikram Joshi', 'Mon', 'Pressure Cooker', 'Let me know once you\'re nearby.', null, false),
        _messageItem('Anita Deshmukh', 'Aug 12', 'Office Chair', 'Is it still available?', null, false),
        _messageItem('Sagar Iyer', 'Aug 11', 'Football', 'Great! See you tomorrow.', null, false),
        _messageItem('Kavya Nair', 'Aug 10', 'Microwave Oven', 'Thanks again!', null, false),
        _messageItem('Community Team', 'Aug 5', 'Welcome to ShareNest!', 'Tips to get started...', null, true, isOfficial: true),
      ],
    );
  }

  Widget _messageItem(String name, String time, String item, String msg, String? badge, bool unread, {bool isOfficial = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isOfficial ? AppColors.primaryLight : AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(isOfficial ? Icons.eco : Icons.image_outlined, color: isOfficial ? AppColors.primary : AppColors.grey300),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(fontSize: 14, fontWeight: unread ? FontWeight.bold : FontWeight.w600)),
                      Text(time, style: TextStyle(fontSize: 11, color: unread ? AppColors.primary : AppColors.textSecondary, fontWeight: unread ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isOfficial) const Icon(Icons.verified, color: AppColors.primary, size: 12) else const CircleAvatar(radius: 6, backgroundColor: AppColors.grey200, child: Icon(Icons.person, size: 8, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      Text(item, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: unread ? AppColors.textPrimary : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStickyInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Meaningful conversations create stronger communities.\nBe respectful. Be kind. Be local.',
              style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
            ),
          )
        ],
      ),
    );
  }
}
