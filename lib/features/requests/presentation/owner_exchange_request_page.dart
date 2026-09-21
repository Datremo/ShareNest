import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class OwnerExchangeRequestPage extends StatelessWidget {
  const OwnerExchangeRequestPage({super.key});

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
        title: const Text('Exchange Request', style: TextStyle(color: AppColors.primaryDark, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      const Text('Accepted', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Today, 4:12 PM', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                
                const SizedBox(height: 24),
                
                Text(
                  'Rahul has accepted your exchange\nrequest! You can now chat and\ncoordinate the exchange.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.4),
                ),
                
                const SizedBox(height: 40),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/nintendo.jpg', width: 80, height: 80, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[200]),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Nintendo Switch', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('From Rahul Sharma', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(CupertinoIcons.arrow_right_arrow_left, color: AppColors.exchange, size: 32),
                    ),
                    
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/images/ps5_controller.jpg', width: 80, height: 80, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.grey[200]),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('PS5 Controller', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Your offer', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 120), // Padding for sticky bottom actions
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
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.exchange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () => context.push('/conversation'),
                      child: const Text('Message Rahul', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () {},
                      child: const Text('View Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/exchange_completed'),
                    child: const Text('Mark as Completed Later', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
