import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/widgets/liquid_glass_widgets.dart';

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
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
            border: Border.all(color: Colors.white, width: 2),
          ),
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 12),
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.grey400.withValues(alpha: 0.5), 
                    borderRadius: BorderRadius.circular(3)
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.primaryDark),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.5)),
                    PhysicsCard(
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedDistance = 'Within 500 m';
                          _selectedCondition = 'Any';
                          _selectedAvailability = 'Available now';
                          _verifiedOnly = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Clear All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 24, color: Colors.black12),
              ),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      const SizedBox(height: 16),
                      _buildCategoriesGrid(),
                      
                      const SizedBox(height: 32),
                      const Text('Distance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
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
                      const Text('Condition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildChip('Any', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                          _buildChip('Like new', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                          _buildChip('Good', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                          _buildChip('Fair', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      const Text('Availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildChip('Available now', _selectedAvailability, (v) => setState(() => _selectedAvailability = v)),
                          _buildChip('Available soon', _selectedAvailability, (v) => setState(() => _selectedAvailability = v)),
                          _buildChip('Flexible', _selectedAvailability, (v) => setState(() => _selectedAvailability = v)),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Colors.blue, size: 24),
                                SizedBox(width: 12),
                                Text('Verified Neighbours Only', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              ],
                            ),
                            CupertinoSwitch(
                              value: _verifiedOnly,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) => setState(() => _verifiedOnly = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.pop({
                              'category': _selectedCategory,
                              'distance': _selectedDistance,
                              'condition': _selectedCondition,
                              'availability': _selectedAvailability,
                              'verifiedOnly': _verifiedOnly,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 48), // Padding for bottom 
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'All', 'icon': Icons.grid_view_rounded},
      {'name': 'Tools', 'icon': Icons.handyman_rounded},
      {'name': 'Electronics', 'icon': Icons.computer_rounded},
      {'name': 'Home', 'icon': Icons.home_rounded},
      {'name': 'Books', 'icon': Icons.menu_book_rounded},
      {'name': 'Sports', 'icon': Icons.sports_basketball_rounded},
      {'name': 'Party', 'icon': Icons.celebration_rounded},
      {'name': 'Kids', 'icon': Icons.child_care_rounded},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['name'] as String),
          child: SizedBox(
            width: 76,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isSelected ? AppColors.primary : Colors.white, width: 2),
                    boxShadow: isSelected 
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] 
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  child: Icon(
                    cat['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.primaryDark,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChip(String label, String groupValue, Function(String) onSelect) {
    final isSelected = label == groupValue;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white, width: 2),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] 
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
