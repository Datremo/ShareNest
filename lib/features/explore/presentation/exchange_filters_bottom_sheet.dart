import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ExchangeFiltersBottomSheet extends StatefulWidget {
  const ExchangeFiltersBottomSheet({super.key});

  @override
  State<ExchangeFiltersBottomSheet> createState() => _ExchangeFiltersBottomSheetState();
}

class _ExchangeFiltersBottomSheetState extends State<ExchangeFiltersBottomSheet> {
  String _selectedExchangeType = 'All';
  String _selectedDistance = 'Within 500 m';
  String _selectedCondition = 'Any';
  bool _verifiedOnly = true;
  
  final List<String> _selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(CupertinoIcons.xmark, color: AppColors.primaryDark), onPressed: () => context.pop()),
                const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Clear All', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                )
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Exchange Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildChip('All', _selectedExchangeType, (v) => setState(() => _selectedExchangeType = v)),
                      const SizedBox(width: 8),
                      _buildChip('I want', _selectedExchangeType, (v) => setState(() => _selectedExchangeType = v)),
                      const SizedBox(width: 8),
                      _buildChip("I'm offering", _selectedExchangeType, (v) => setState(() => _selectedExchangeType = v)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.start,
                    children: [
                      _buildCategoryItem(Icons.computer, 'Electronics'),
                      _buildCategoryItem(Icons.kitchen, 'Home &\nKitchen'),
                      _buildCategoryItem(Icons.menu_book, 'Books'),
                      _buildCategoryItem(Icons.checkroom, 'Clothing'),
                      _buildCategoryItem(Icons.sports_basketball, 'Sports'),
                      _buildCategoryItem(Icons.toys, 'Toys &\nGames'),
                      _buildCategoryItem(Icons.park, 'Outdoor'),
                      _buildCategoryItem(Icons.more_horiz, 'Others'),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('Distance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('Any', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                      _buildChip('Like new', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                      _buildChip('Good', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                      _buildChip('Fair', _selectedCondition, (v) => setState(() => _selectedCondition = v)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Verified users only', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      CupertinoSwitch(
                        activeColor: AppColors.exchange,
                        value: _verifiedOnly,
                        onChanged: (v) => setState(() => _verifiedOnly = v),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Button
          Container(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.exchange,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () => context.pop(),
                child: const Text('Apply Filters (42 items)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChip(String label, String selectedValue, Function(String) onSelect) {
    bool isSelected = label == selectedValue;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.exchange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.exchange : Colors.grey[300]!),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : AppColors.primaryDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        )),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    bool isSelected = _selectedCategories.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategories.remove(label);
          } else {
            _selectedCategories.add(label);
          }
        });
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.exchange.withValues(alpha: 0.1) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.exchange : Colors.grey[200]!),
              ),
              child: Icon(icon, color: isSelected ? AppColors.exchange : Colors.grey[600], size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.exchange : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}
