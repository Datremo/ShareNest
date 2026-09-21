import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class UpdateLendingPage extends StatelessWidget {
  const UpdateLendingPage({super.key});

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
        title: const Text('Update Lending', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/drill.jpg', width: 64, height: 64, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(width: 64, height: 64, color: Colors.grey[200]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Currently Lent to', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const Text('Rahul Mehta', style: TextStyle(color: AppColors.primaryDark, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('16 Sep – 19 Sep 2025\n(3 days)', style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            _buildActionItem(
              context: context,
              icon: Icons.add,
              iconColor: Colors.blue,
              iconBgColor: Colors.blue.withValues(alpha: 0.1),
              title: 'Extend Lending Period',
              onTap: () {},
            ),
            const Padding(padding: EdgeInsets.only(left: 60), child: Divider(color: Colors.black12, height: 1)),
            _buildActionItem(
              context: context,
              icon: Icons.update,
              iconColor: Colors.blue,
              iconBgColor: Colors.blue.withValues(alpha: 0.1),
              title: 'Update Availability\n(after return)',
              onTap: () {},
            ),
            const Padding(padding: EdgeInsets.only(left: 60), child: Divider(color: Colors.black12, height: 1)),
            _buildActionItem(
              context: context,
              icon: Icons.check_circle_outline,
              iconColor: AppColors.success,
              iconBgColor: AppColors.success.withValues(alpha: 0.1),
              title: 'Mark as Returned',
              onTap: () => context.push('/mark_as_returned'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500))),
            const Icon(CupertinoIcons.chevron_forward, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
