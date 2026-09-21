import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class LiveRequestsPage extends StatefulWidget {
  const LiveRequestsPage({super.key});

  @override
  State<LiveRequestsPage> createState() => _LiveRequestsPageState();
}

class _LiveRequestsPageState extends State<LiveRequestsPage> {
  String _selectedType = 'Nearby';
  String _selectedDistance = '500 m';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            const Text('Live Requests', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 20)),
            const Text('Neighbours who need something right now.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLiveStatusRow(),
          const SizedBox(height: 16),
          _buildTypeChips(),
          const SizedBox(height: 12),
          _buildDistanceChips(),
          const SizedBox(height: 16),
          _buildMapSection(),
          _buildListHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildLiveCard('Need USB-C Charger', 'usb_charger.jpg', 'My phone is at 2%. Shops are closed. Need for 1-2 hours.', '320 m', '2 min ago', 'avatar_man.jpg', '4.9 (28)', 'Borrow for 2 hours'),
                const SizedBox(height: 12),
                _buildLiveCard('Need Extension Board', 'extension_board.jpg', 'Working from home. Need an extension board for tonight.', '480 m', '5 min ago', 'avatar_woman.jpg', '4.8 (16)', 'Borrow for tonight'),
                const SizedBox(height: 12),
                _buildLiveCard('Need Umbrella', 'camping_tent.jpg', "It's raining and I need an umbrella to reach home. Need for 1 hour.", '650 m', '8 min ago', 'avatar_man.jpg', '4.7 (12)', 'Borrow for 1 hour'),
                const SizedBox(height: 12),
                _buildLiveCard('Need Power Bank', 'usb_charger.jpg', 'Phone dying. Need a power bank for 3-4 hours.', '780 m', '12 min ago', 'avatar_man.jpg', '4.6 (9)', 'Borrow for 4 hours'),
                const SizedBox(height: 24),
                _buildSafetyBanner(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.error),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('LIVE • updates in real time', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('4 active requests', style: TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChips() {
    final types = [
      {'label': 'Nearby', 'icon': Icons.location_on},
      {'label': 'Urgent', 'icon': Icons.bolt},
      {'label': 'Borrow', 'icon': Icons.chat_bubble_outline},
      {'label': 'Alll', 'icon': Icons.grid_view}, // typo matching design
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: types.map((t) {
          final isSelected = _selectedType == t['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedType = t['label'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? (t['label'] == 'Urgent' ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1)) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? (t['label'] == 'Urgent' ? AppColors.error : AppColors.primary) : Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData, size: 14, color: isSelected ? (t['label'] == 'Urgent' ? AppColors.error : AppColors.primary) : AppColors.primaryDark),
                  const SizedBox(width: 4),
                  Text(t['label'] as String, style: TextStyle(
                    color: isSelected ? (t['label'] == 'Urgent' ? AppColors.error : AppColors.primary) : AppColors.primaryDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistanceChips() {
    final distances = ['500 m', '1 km', '2 km', '5 km'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: distances.map((d) {
          final isSelected = _selectedDistance == d;
          return GestureDetector(
            onTap: () => setState(() => _selectedDistance = d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
              ),
              child: Text(d, style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/map_placeholder.jpg', fit: BoxFit.cover),
              // Simulating pins
              const Positioned(top: 30, left: 60, child: _MapPin()),
              const Positioned(top: 80, left: 120, child: _MapPin()),
              const Positioned(top: 20, right: 100, child: _MapPin()),
              const Positioned(bottom: 20, right: 60, child: _MapPin()),
              Positioned(
                top: 40,
                right: 40,
                child: Column(
                  children: [
                    const Text('Sainagar', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    const Text('Old Panvel', style: TextStyle(color: AppColors.primaryDark)),
                  ],
                ),
              ),
              // Blue user dot
              Positioned(
                top: 70,
                left: 170,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 4)],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        child: const Text('4', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      const Text('4 requests nearby', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.my_location, size: 16, color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Live Requests Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          Row(
            children: [
              const Text('Sort: Nearest', style: TextStyle(fontSize: 12, color: AppColors.primaryDark)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard(String title, String image, String desc, String dist, String time, String avatar, String rating, String borrowTime) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/images/$image', width: 72, height: 72, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: AppColors.error, size: 12),
                            const Text(' URGENT', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(time, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
                    const SizedBox(height: 4),
                    Text('"$desc"', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                        Text(' $dist • Sainagar, Old Panvel', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  CircleAvatar(radius: 12, backgroundImage: AssetImage('assets/images/$avatar')),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      Text(rating, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(borrowTime, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                  const SizedBox(width: 12),
                  const Icon(Icons.local_fire_department, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  const Text('Needed now', style: TextStyle(fontSize: 12, color: AppColors.error)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {},
                child: const Text('Can you help?', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stay Safe', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                Text('Only respond if you can safely help.\nMeet in a public place and trust your instincts.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: AppColors.success),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.location_on, color: AppColors.error, size: 32),
        const Positioned(
          top: 6,
          child: Icon(Icons.bolt, color: Colors.white, size: 12),
        ),
      ],
    );
  }
}