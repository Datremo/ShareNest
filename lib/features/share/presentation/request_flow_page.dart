import 'package:flutter/material.dart';
import '../../../core/presentation/widgets/liquid_glass_container.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class RequestFlowPage extends StatelessWidget {
  const RequestFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        title: const Text('Request to Borrow', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItemSummary(),
                const SizedBox(height: 32),
                _buildStepHeader('1', 'Select duration', 'How long do you need it?'),
                _buildDurationChips(),
                const SizedBox(height: 32),
                _buildStepHeader('2', 'Select date & time', 'When would you like to pick it up?'),
                _buildDateSelector(),
                const SizedBox(height: 16),
                _buildTimeSelector(),
                const SizedBox(height: 32),
                _buildStepHeader('3', 'Pickup location', 'Where will you meet?'),
                _buildLocationCard(),
                const SizedBox(height: 32),
                _buildStepHeader('4', 'Add a message (optional)', 'Introduce yourself or share any details'),
                _buildMessageInput(),
                const SizedBox(height: 32),
                _buildRequestSummary(),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/request_confirmed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      icon: const Icon(Icons.send_outlined, color: Colors.white, size: 20),
                      label: const Text('Send Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The owner will be notified and can accept or decline your request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItemSummary() {
    return Row(
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
    );
  }

  Widget _buildStepHeader(String stepNum, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
              child: Text(stepNum, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1.0)),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDurationChips() {
    final durations = ['30 minutes', '2 hours', '4 hours', '3 days', 'Custom'];
    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: durations.map((d) {
          final isSelected = d == '4 hours';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.grey200),
            ),
            child: Text(
              d,
              style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector() {
    final dates = [
      {'day': 'Today', 'date': 'Sep 14', 'active': true},
      {'day': 'Tomorrow', 'date': 'Sep 15', 'active': false},
      {'day': 'Tue', 'date': 'Sep 16', 'active': false},
      {'day': 'Wed', 'date': 'Sep 17', 'active': false},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final d = dates[index];
            final isActive = d['active'] as bool;
            return Container(
              margin: const EdgeInsets.only(right: 12),
              width: 75,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? AppColors.primary : AppColors.grey200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(d['day'] as String, style: TextStyle(fontSize: 12, color: isActive ? AppColors.primaryDark : AppColors.textPrimary, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(d['date'] as String, style: TextStyle(fontSize: 12, color: isActive ? AppColors.primaryDark : AppColors.textSecondary, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferred time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 20, color: AppColors.textPrimary),
                    SizedBox(width: 12),
                    Text('6:00 PM - 10:00 PM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                Icon(Icons.edit_outlined, size: 20, color: AppColors.textPrimary),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.map, size: 40, color: AppColors.grey300)),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Sainagar, Old Panvel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('320 m away', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Meet at society gate (recommended)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Meet in a safe, public place. Exact address will be shared after request is accepted.',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: const Text(
              "Hi! I'd like to borrow this drill for a small home project. I'll take good care of it and return it on time. Thanks!",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
          const Text('0/300', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRequestSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 10),
            ),
            const SizedBox(width: 8),
            const Text('Request summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        _summaryRow('Item', 'Cordless Drill'),
        _summaryRow('Duration', '4 hours'),
        _summaryRow('Date & time', 'Today, 6:00 PM - 10:00 PM'),
        _summaryRow('Pickup location', 'Society gate, Sainagar'),
        _summaryRow('Return location', 'Same as pickup'),
        _summaryRow('Extension', 'Allowed'),
      ],
    );
  }

  Widget _summaryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
