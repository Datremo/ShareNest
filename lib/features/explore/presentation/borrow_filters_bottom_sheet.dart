import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class BorrowFiltersBottomSheet extends StatefulWidget {
  const BorrowFiltersBottomSheet({super.key});

  @override
  State<BorrowFiltersBottomSheet> createState() => _BorrowFiltersBottomSheetState();
}

class _BorrowFiltersBottomSheetState extends State<BorrowFiltersBottomSheet> {
  String _selectedDistance = 'Within 1 km';
  String _selectedCondition = 'Any';
  String _selectedAvailability = 'Available now';
  bool _verifiedOnly = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      height: MediaQuery.of(context).size.height * 0.85,
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
                  const Text('Availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildChip('Available now', _selectedAvailability, (v) => setState(() => _selectedAvailability = v)),
                      _buildChip('Today', _selectedAvailability, (v) => setState(() => _selectedAvailability = v)),
                      _buildChip('This week', _selectedAvailability, (v) => setState(() => _selectedAvailability = v)),
                      _buildChip('Custom dates', _selectedAvailability, (v) => setState(() => _selectedAvailability = v)),
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
                      _buildChip('Fair', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                      _buildChip('Used', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Verified users only', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 16)),
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
                child: const Text('Apply Filters (12 items)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
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
