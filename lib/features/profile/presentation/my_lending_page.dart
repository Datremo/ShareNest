import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MyLendingPage extends StatefulWidget {
  const MyLendingPage({super.key});

  @override
  State<MyLendingPage> createState() => _MyLendingPageState();
}

class _MyLendingPageState extends State<MyLendingPage> {
  String _selectedFilter = 'Active (3)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Lending', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFilterChips(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildActiveLendingCard(
                  title: 'Cordless Drill',
                  image: 'drill.jpg',
                  borrower: 'Amit Verma',
                  until: 'Thu, 18 Sep, 7:00 PM',
                  remaining: '1d 3h remaining',
                ),
                const SizedBox(height: 12),
                _buildActiveLendingCard(
                  title: 'Ladder',
                  image: 'ladder.jpg',
                  borrower: 'Sneha Kulkarni',
                  until: 'Sat, 20 Sep, 6:00 PM',
                  remaining: '3d 5h remaining',
                ),
                const SizedBox(height: 12),
                _buildActiveLendingCard(
                  title: 'Camera',
                  image: 'camera.jpg',
                  borrower: 'Rohan Desai',
                  until: 'Mon, 22 Sep, 9:00 PM',
                  remaining: '5d 8h remaining',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Active (3)', 'Requests (1)', 'Past (6)'];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveLendingCard({
    required String title,
    required String image,
    required String borrower,
    required String until,
    required String remaining,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/images/$image', width: 64, height: 64, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64, height: 64, color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark)),
                    const SizedBox(height: 4),
                    Text('To: $borrower', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Until: $until', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(remaining, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      const Text('Message', style: TextStyle(color: AppColors.primaryDark, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text('View Details', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
