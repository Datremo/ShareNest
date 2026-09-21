import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  String _selectedFilter = 'All (8)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Posts', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
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
                const Text('Active Posts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                _buildActivePostCard(
                  title: 'Books (Assorted)',
                  image: 'books.jpg',
                  type: 'Give',
                  typeColor: AppColors.error, // Red for give
                  views: '34 views',
                  requests: '6 requests',
                  postedTime: 'Posted 2 days ago',
                ),
                const SizedBox(height: 12),
                _buildActivePostCard(
                  title: 'Cordless Drill',
                  image: 'drill.jpg',
                  type: 'Lend',
                  typeColor: AppColors.success, // Green for lend
                  views: '28 views',
                  requests: '4 requests',
                  postedTime: 'Posted 5 days ago',
                ),
                const SizedBox(height: 12),
                _buildActivePostCard(
                  title: 'Office Chair',
                  image: 'office_chair.jpg',
                  type: 'Give',
                  typeColor: AppColors.error,
                  views: '41 views',
                  requests: '8 requests',
                  postedTime: 'Posted 1 week ago',
                ),
                const SizedBox(height: 12),
                _buildActivePostCard(
                  title: 'Yoga Mat',
                  image: 'yoga_mat.jpg',
                  type: 'Lend',
                  typeColor: AppColors.success,
                  views: '19 views',
                  requests: '3 requests',
                  postedTime: 'Posted 1 week ago',
                ),
                const SizedBox(height: 24),
                const Text('Inactive Posts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                _buildInactivePostCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All (8)', 'Lending (4)', 'Giving (2)', 'Exchange (2)'];
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

  Widget _buildActivePostCard({
    required String title,
    required String image,
    required String type,
    required Color typeColor,
    required String views,
    required String requests,
    required String postedTime,
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
      child: Row(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark)),
                    const Icon(Icons.more_vert, size: 16, color: AppColors.primaryDark),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(type == 'Give' ? Icons.favorite_border : Icons.handshake_outlined, size: 12, color: typeColor),
                    const SizedBox(width: 4),
                    Text(type, style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(views, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    Container(
                      width: 1, height: 10, color: Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Text(requests, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(postedTime, style: TextStyle(fontSize: 10, color: Colors.blueGrey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactivePostCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Faded background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: 0.6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/table_lamp.jpg', width: 64, height: 64, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 64, height: 64, color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Table Lamp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark)),
                    const Icon(Icons.more_vert, size: 16, color: AppColors.primaryDark),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 10, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Text('Completed', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Given to Neha Patil', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('Completed on 10 Sep 2025', style: TextStyle(fontSize: 10, color: Colors.blueGrey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
