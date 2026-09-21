import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class FiltersBottomSheet extends StatefulWidget {
  const FiltersBottomSheet({super.key});

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  String _selectedCategory = 'All';
  String _selectedDistance = 'Within 500 m';
  String _selectedCondition = 'Any';
  String _selectedAvailability = 'Available now';
  bool _verifiedOnly = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      // Set to take up most of the screen
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.primaryDark),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context.pop(),
                ),
                const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: const Text('Clear All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                )
              ],
            ),
          ),
          const Divider(height: 24, color: Colors.black12),
          
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  _buildCategoriesGrid(),
                  
                  const SizedBox(height: 32),
                  const Text('Distance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildChip('Within 500 m', _selectedDistance, (v) => setState(() => _selectedDistance = v)),
                      _buildChip('Within 1 km', _selectedDistance, (v) => setState(() => _selectedDistance = v)),
                      _buildChip('Within 2 km', _selectedDistance, (v) => setState(() => _selectedDistance = v)),
                      _buildChip('Within 5 km', _selectedDistance, (v) => setState(() => _selectedDistance = v)),
                      _buildChip('10+ km', _selectedDistance, (v) => setState(() => _selectedDistance = v)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Condition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildChip('Any', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                      _buildChip('Like new', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                      _buildChip('Good', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                      _buildChip('Used', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildChip('Available now', _selectedAvailability, (v) => setState(() => _selectedAvailability = v))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildChip('This week', _selectedAvailability, (v) => setState(() => _selectedAvailability = v))),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text('Verified users only', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 15)),
                      ),
                      CupertinoSwitch(
                        value: _verifiedOnly,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _verifiedOnly = v),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () => context.pop(),
                child: const Text('Apply Filters (48 items)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view_rounded, 'color': AppColors.primary},
      {'name': 'Food', 'icon': Icons.restaurant_rounded, 'color': Colors.orange},
      {'name': 'Books', 'icon': Icons.menu_book_rounded, 'color': Colors.blue},
      {'name': 'Clothing', 'icon': Icons.checkroom_rounded, 'color': Colors.purple},
      {'name': 'Home', 'icon': Icons.home_rounded, 'color': Colors.green},
      {'name': 'Electronics', 'icon': Icons.phone_iphone_rounded, 'color': Colors.teal},
      {'name': 'Furniture', 'icon': Icons.chair_rounded, 'color': Colors.brown},
      {'name': 'Baby & Kids', 'icon': Icons.child_care_rounded, 'color': Colors.pink},
      {'name': 'Others', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: categories.map((cat) {
        bool isSelected = _selectedCategory == cat['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['name'] as String),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[200]!),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'] as IconData, color: isSelected ? Colors.white : (cat['color'] as Color), size: 24),
                const SizedBox(height: 6),
                Text(cat['name'] as String, style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primaryDark,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChip(String label, String groupValue, Function(String) onSelect) {
    bool isSelected = label == groupValue;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryDark, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ), textAlign: TextAlign.center),
      ),
    );
  }
}
