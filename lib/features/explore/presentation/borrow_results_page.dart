import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'borrow_filters_bottom_sheet.dart';

class BorrowResultsPage extends StatefulWidget {
  const BorrowResultsPage({super.key});

  @override
  State<BorrowResultsPage> createState() => _BorrowResultsPageState();
}

class _BorrowResultsPageState extends State<BorrowResultsPage> {
  bool _isListView = true;

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BorrowFiltersBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Explore Results', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildViewToggles(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('12 items nearby', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          const Text('Sort', style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w600)),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primaryDark),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => context.push('/borrow_detail'),
                    child: _buildItemCard(
                      title: 'Cordless Drill',
                      subtitle: 'Bosch',
                      rating: '4.9 (27)',
                      distance: '320 m',
                      location: 'Sainagar',
                      availability: 'Available now',
                      image: 'assets/images/cordless_drill.jpg', // assume this exists or use fallback
                    ),
                  ),
                  _buildItemCard(
                    title: 'Drill Machine (Wired)',
                    subtitle: 'Makita',
                    rating: '4.8 (16)',
                    distance: '450 m',
                    location: 'Ekta Society',
                    availability: 'Available today',
                    image: 'assets/images/drill.jpg',
                  ),
                  _buildItemCard(
                    title: 'Hammer Drill',
                    subtitle: 'DeWalt',
                    rating: '4.7 (11)',
                    distance: '680 m',
                    location: 'Old Panvel',
                    availability: 'Available now',
                    image: 'assets/images/drill.jpg',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Icon(CupertinoIcons.search, color: AppColors.primary, size: 20),
          ),
          const Expanded(
            child: Text('drill', style: TextStyle(fontSize: 16, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () {}),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryDark),
            onPressed: _showFilters,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildViewToggles() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isListView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isListView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: !_isListView ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_outlined, color: !_isListView ? Colors.white : Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text('Map View', style: TextStyle(color: !_isListView ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isListView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isListView ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _isListView ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_list_bulleted_rounded, color: _isListView ? Colors.white : Colors.grey[600], size: 18),
                    const SizedBox(width: 8),
                    Text('List View', style: TextStyle(color: _isListView ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard({required String title, required String subtitle, required String rating, required String distance, required String location, required String availability, required String image}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: Image.asset(image, width: 110, height: 140, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(width: 110, height: 140, color: Colors.grey[200]),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const Icon(CupertinoIcons.heart, color: AppColors.primaryDark, size: 20),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text('$distance • $location', style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(availability, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
