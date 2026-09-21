import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ImpactSummaryPage extends StatelessWidget {
  const ImpactSummaryPage({super.key});

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
        title: const Text('Impact Summary', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            Text('This item has been lent', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            const Text('6 times', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
            
            const SizedBox(height: 48),
            
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.people_outline,
                  value: '6',
                  label: 'People\nhelped',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.calendar_today_outlined,
                  value: '18',
                  label: 'Days in\nuse',
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  icon: Icons.eco_outlined,
                  value: '~12 kg',
                  label: 'Waste\nreduced',
                  color: Colors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(Icons.eco, color: Colors.green[400], size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Small actions create a bigger, kinder tomorrow.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              'See the positive impact\nyour item has created!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryDark)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.2)),
        ],
      ),
    );
  }
}
