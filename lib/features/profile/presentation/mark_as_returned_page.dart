import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class MarkAsReturnedPage extends StatefulWidget {
  const MarkAsReturnedPage({super.key});

  @override
  State<MarkAsReturnedPage> createState() => _MarkAsReturnedPageState();
}

class _MarkAsReturnedPageState extends State<MarkAsReturnedPage> {
  String _selectedCondition = 'Good';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mark as Returned', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 160,
                  alignment: Alignment.center,
                  child: Image.asset('assets/images/returned_illustration.jpg', fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Mark as Returned', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Text(
                  'Confirm that you have received\nyour item back in good condition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
                ),
                
                const SizedBox(height: 40),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Condition on Return', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildConditionChip('Good', Icons.check_circle, AppColors.success),
                    const SizedBox(width: 8),
                    _buildConditionChip('Fair', Icons.remove_circle, Colors.orange),
                    const SizedBox(width: 8),
                    _buildConditionChip('Damaged', Icons.cancel, AppColors.error),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Add a note (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextFormField(
                    maxLines: 3,
                    initialValue: 'Item returned in great condition. Thanks, Rahul!',
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4),
                  ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
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
                    backgroundColor: AppColors.success,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => context.push('/lending_completed'),
                  child: const Text('Confirm Return', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildConditionChip(String label, IconData icon, Color activeColor) {
    final isSelected = _selectedCondition == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCondition = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isSelected ? activeColor : Colors.grey[300]!),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Icon(icon, color: activeColor, size: 16),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(
                color: isSelected ? activeColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
