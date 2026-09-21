import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/liquid_glass_container.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class RequestConfirmedPage extends StatelessWidget {
  const RequestConfirmedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 32),
            _buildItemSummary(),
            const SizedBox(height: 24),
            _buildRequestDetails(),
            const SizedBox(height: 24),
            _buildStatusTimeline(),
            const SizedBox(height: 32),
            _buildTipsBox(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 32),
            _buildKinderCommunityBox(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send, color: Colors.white, size: 36),
              ),
            ),
            // Confetti dots representation
            Positioned(top: 10, left: 20, child: _dot(Colors.amber)),
            Positioned(top: 30, right: 10, child: _dot(Colors.blue)),
            Positioned(bottom: 20, left: 10, child: _dot(Colors.red)),
            Positioned(bottom: 10, right: 30, child: _dot(Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Request Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Rahul has been notified about your request.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Text("You'll get a notification once they respond.", style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _dot(Color color) {
    return Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  Widget _buildItemSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Requested item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/images/usb_cable.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cordless Drill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('By Rahul Sharma', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    CircleAvatar(radius: 8, backgroundImage: AssetImage('assets/images/profile_pic.jpg')),
                    SizedBox(width: 4),
                    Icon(Icons.star, color: Colors.amber, size: 12),
                    Text(' 4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(' (27 reviews)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                )
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildRequestDetails() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Request details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey200),
              ),
              child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        _detailRow('Duration', '4 hours'),
        _detailRow('Date & time', 'Today, 6:00 PM – 10:00 PM'),
        _detailRow('Pickup location', 'Society gate, Sainagar'),
        _detailRow('Return location', 'Same as pickup'),
        _detailRow('Extension', 'Allowed'),
        _detailRow('Message', "Hi! I'd like to borrow this drill for a small home project. I'll take good care of it and return it on time. Thanks!", maxLines: 3),
      ],
    );
  }

  Widget _detailRow(String label, String val, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: maxLines, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _timelineNode('Request sent', 'Today, 1:24 PM\nRahul has been notified.', isCompleted: true, isLast: false),
        _timelineNode('Owner responding', "You'll be notified soon.", isCompleted: false, isLast: false),
        _timelineNode('Request accepted', "You'll receive pickup details.", isCompleted: false, isLast: false),
        _timelineNode('Item pickup', 'Meet the owner and confirm.', isCompleted: false, isLast: false),
        _timelineNode('Item in use', 'Enjoy and return on time.', isCompleted: false, isLast: false),
        _timelineNode('Return completed', 'Both you and the owner will confirm.', isCompleted: false, isLast: true),
      ],
    );
  }

  Widget _timelineNode(String title, String subtitle, {required bool isCompleted, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primaryDark : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? AppColors.primaryDark : AppColors.grey300, width: 2),
              ),
              child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.grey200,
              )
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: isCompleted ? FontWeight.bold : FontWeight.w600, color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTipsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('While you wait...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          _bulletPoint('You can message the owner for any questions.'),
          _bulletPoint('Be ready to pick up at the selected time.'),
          _bulletPoint('Check your notifications for updates.'),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: AppColors.textPrimary)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryDark),
            label: const Text('Message Owner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.grey300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => context.go('/'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: const Text('Cancel Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildKinderCommunityBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco, color: AppColors.primaryDark, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('A kinder community', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark)),
                SizedBox(height: 6),
                Text('Thank you for choosing to borrow instead of buying. Together we build stronger, more sustainable neighbourhoods!', style: TextStyle(fontSize: 12, color: AppColors.primaryDark, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
